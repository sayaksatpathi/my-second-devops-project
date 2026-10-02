#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$PROJECT_ROOT/terraform/environments/dev"

REGION="ap-south-1"
CLUSTER_NAME="opsforge-dev"
VPC_ID="vpc-004073b6f7f207060"
NODE_SG="sg-006a390ee4a5ff3e7"

REDIS_SG_NAME="opsforge-dev-redis"

echo "=============================================="
echo " OpsForge - Redis Networking Fix"
echo "=============================================="

command -v aws >/dev/null || {
  echo "ERROR: aws CLI is not installed."
  exit 1
}

command -v terraform >/dev/null || {
  echo "ERROR: terraform is not installed."
  exit 1
}

command -v kubectl >/dev/null || {
  echo "ERROR: kubectl is not installed."
  exit 1
}

echo
echo "[1/7] Checking AWS identity..."
aws sts get-caller-identity

echo
echo "[2/7] Looking for Redis security group..."

REDIS_SG_ID="$(
  aws ec2 describe-security-groups \
    --region "$REGION" \
    --filters \
      "Name=vpc-id,Values=$VPC_ID" \
      "Name=group-name,Values=$REDIS_SG_NAME" \
    --query 'SecurityGroups[0].GroupId' \
    --output text
)"

if [[ "$REDIS_SG_ID" == "None" || -z "$REDIS_SG_ID" ]]; then
  echo "Creating Redis security group..."

  REDIS_SG_ID="$(
    aws ec2 create-security-group \
      --region "$REGION" \
      --group-name "$REDIS_SG_NAME" \
      --description "Allow Redis traffic from EKS worker nodes" \
      --vpc-id "$VPC_ID" \
      --query 'GroupId' \
      --output text
  )

  echo "Created: $REDIS_SG_ID"
else
  echo "Found: $REDIS_SG_ID"
fi

echo
echo "[3/7] Ensuring Redis ingress rule exists..."

if aws ec2 describe-security-group-rules \
    --region "$REGION" \
    --filters "Name=group-id,Values=$REDIS_SG_ID" \
    --query "SecurityGroupRules[?IsEgress==\`false\` && FromPort==\`6379\` && ToPort==\`6379\` && ReferencedGroupId==\`$NODE_SG\`]" \
    --output text | grep -q "$NODE_SG"; then

  echo "Redis ingress rule already exists."

else

  aws ec2 authorize-security-group-ingress \
    --region "$REGION" \
    --group-id "$REDIS_SG_ID" \
    --protocol tcp \
    --port 6379 \
    --source-group "$NODE_SG"

  echo "Added TCP/6379 from EKS node SG."
fi

echo
echo "[4/7] Updating Terraform configuration..."

python3 - "$TF_DIR/main.tf" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

if 'resource "aws_security_group" "redis"' not in text:
    marker = '\nmodule "redis" {'

    block = r'''
resource "aws_security_group" "redis" {
  name        = "${local.name}-redis"
  description = "Allow Redis traffic from EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Redis from EKS nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-redis"
  })
}
'''

    if marker not in text:
        raise SystemExit("Could not find module \"redis\" block.")

    text = text.replace(marker, "\n" + block + "\nmodule \"redis\" {", 1)

old = '''module "redis" {
  source     = "../../modules/redis"
  name       = local.name
  subnet_ids = module.vpc.private_subnet_ids
  num_nodes  = 1 # dev
  tags       = local.tags
}'''

new = '''module "redis" {
  source             = "../../modules/redis"
  name               = local.name
  subnet_ids         = module.vpc.private_subnet_ids
  num_nodes          = 1 # dev
  security_group_ids = [aws_security_group.redis.id]
  tags               = local.tags
}'''

if old in text:
    text = text.replace(old, new, 1)
elif 'security_group_ids = [aws_security_group.redis.id]' not in text:
    raise SystemExit("Could not update Redis module block.")

path.write_text(text)
PY

echo
echo "[5/7] Terraform fmt + validate..."

terraform -chdir="$TF_DIR" fmt
terraform -chdir="$TF_DIR" validate

echo
echo "[6/7] Terraform plan..."

terraform -chdir="$TF_DIR" plan

echo
echo "=============================================="
echo " PLAN COMPLETE"
echo "=============================================="
echo
echo "Review the plan above."
echo
echo "If it shows only Redis SG creation/attachment,"
echo "apply with:"
echo
echo "terraform -chdir=$TF_DIR apply"
echo
echo "After apply, continue with the connectivity test."

# Runbook: Certificate Expiry

**Related alert(s):** `CertExpiringSoon`

## Symptoms
- TLS handshake failures imminent; cert within renewal window.

## Diagnose
- Check ACM / cert-manager status and expiry dates; verify DNS validation records.

## Mitigate (stop the bleeding)
- Renew/rotate the certificate; roll the ingress/ALB to pick up the new cert.

## Resolve & verify
- Confirm the signal returns to baseline on the Grafana dashboard.
- Confirm the alert clears in Alertmanager.

## Prevent (follow-up)
- Automate renewal (ACM/cert-manager); alert >30 days before expiry.

> Template: keep runbooks short, ordered, and action-first. After any
> user-impacting incident, write a postmortem (see `../postmortem-template.md`).

"""OpsForge Worker — async background consumer (scaffold).

In a later phase this consumes events from Kafka (e.g. the "orders" topic) and
does notification/analytics/billing work. For now it's a simple heartbeat loop
so it builds, runs, and can be deployed/observed like a real workload.
"""
import os
import time


def main() -> None:
    interval = float(os.environ.get("WORKER_INTERVAL", "5"))
    print("opsforge-worker started", flush=True)
    while True:
        # TODO(phase: event-driven): poll Kafka consumer, process messages.
        print("worker heartbeat", flush=True)
        time.sleep(interval)


if __name__ == "__main__":
    main()

"""OpsForge Order API — minimal FastAPI stub.

Scaffold: creates orders and emits an event to Kafka (wired in a later phase).
"""
import os

from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="OpsForge Order API", version="0.1.0")

_orders: list[dict] = []


class Order(BaseModel):
    user_id: int
    item: str
    qty: int = 1


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.post("/orders", status_code=201)
def create_order(order: Order):
    record = {"id": len(_orders) + 1, **order.model_dump()}
    _orders.append(record)
    # TODO(phase: event-driven): publish to Kafka topic "orders"
    return record


@app.get("/orders")
def list_orders():
    return {"orders": _orders, "count": len(_orders)}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "8001")))

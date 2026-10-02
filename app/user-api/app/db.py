"""Persistence layer. Uses PostgreSQL when DATABASE_URL is set; otherwise an
in-memory store so the service runs with zero external dependencies (and tests
need no database)."""
import logging
import threading

logger = logging.getLogger("user-api.db")


class InMemoryStore:
    """Thread-safe in-memory user store (fallback / test mode)."""

    def __init__(self) -> None:
        self._users: dict[int, dict] = {}
        self._seq = 0
        self._lock = threading.Lock()

    def create(self, name: str, email: str) -> dict:
        with self._lock:
            self._seq += 1
            rec = {"id": self._seq, "name": name, "email": email}
            self._users[self._seq] = rec
            return rec

    def get(self, user_id: int) -> dict | None:
        return self._users.get(user_id)

    def list(self) -> list[dict]:
        return list(self._users.values())

    def ping(self) -> bool:
        return True


class PostgresStore:
    """PostgreSQL-backed store via SQLAlchemy Core."""

    def __init__(self, url: str) -> None:
        from sqlalchemy import (
            Column, Integer, MetaData, String, Table, create_engine, insert, select,
        )

        self._engine = create_engine(url, pool_pre_ping=True, pool_size=5)
        self._md = MetaData()
        self._users = Table(
            "users", self._md,
            Column("id", Integer, primary_key=True),
            Column("name", String(255), nullable=False),
            Column("email", String(255), nullable=False, unique=True, index=True),
        )
        self._md.create_all(self._engine)  # dev convenience; prod uses migrations
        self._insert, self._select = insert, select
        logger.info("connected to postgres", extra={"extra_fields": {"backend": "postgres"}})

    def create(self, name: str, email: str) -> dict:
        with self._engine.begin() as conn:
            res = conn.execute(self._insert(self._users).values(name=name, email=email))
            uid = res.inserted_primary_key[0]
            return {"id": uid, "name": name, "email": email}

    def get(self, user_id: int) -> dict | None:
        with self._engine.connect() as conn:
            row = conn.execute(
                self._select(self._users).where(self._users.c.id == user_id)
            ).mappings().first()
            return dict(row) if row else None

    def list(self) -> list[dict]:
        with self._engine.connect() as conn:
            return [dict(r) for r in conn.execute(self._select(self._users)).mappings()]

    def ping(self) -> bool:
        from sqlalchemy import text

        try:
            with self._engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            return True
        except Exception:
            return False


def make_store(database_url: str | None):
    if database_url:
        try:
            return PostgresStore(database_url)
        except Exception as exc:  # fall back rather than crash
            logger.error("postgres init failed, using in-memory: %s", exc)
    logger.info("using in-memory store", extra={"extra_fields": {"backend": "memory"}})
    return InMemoryStore()

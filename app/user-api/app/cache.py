"""Redis cache wrapper with graceful degradation and hit/miss metrics."""
import json
import logging

from prometheus_client import Counter

logger = logging.getLogger("user-api.cache")

CACHE_HITS = Counter("cache_hits_total", "Cache hits.", ["key_type"])
CACHE_MISSES = Counter("cache_misses_total", "Cache misses.", ["key_type"])


class Cache:
    def __init__(self, url: str | None, ttl: int) -> None:
        self._ttl = ttl
        self._client = None
        if url:
            try:
                import redis

                self._client = redis.Redis.from_url(url, socket_timeout=1, decode_responses=True)
                self._client.ping()
                logger.info("connected to redis")
            except Exception as exc:
                logger.error("redis unavailable, caching disabled: %s", exc)
                self._client = None

    @property
    def enabled(self) -> bool:
        return self._client is not None

    def get_user(self, user_id: int) -> dict | None:
        if not self._client:
            return None
        try:
            raw = self._client.get(f"user:{user_id}")
        except Exception:
            return None  # degrade: treat as miss on any Redis error
        if raw:
            CACHE_HITS.labels("user").inc()
            return json.loads(raw)
        CACHE_MISSES.labels("user").inc()
        return None

    def set_user(self, user: dict) -> None:
        if not self._client:
            return
        try:
            self._client.setex(f"user:{user['id']}", self._ttl, json.dumps(user))
        except Exception:
            pass  # cache writes are best-effort

    def ping(self) -> bool:
        if not self._client:
            return False
        try:
            return bool(self._client.ping())
        except Exception:
            return False

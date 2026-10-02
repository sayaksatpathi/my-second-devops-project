import http from "k6/http";
import { check, sleep } from "k6";

const BASE = __ENV.TARGET || "http://localhost:8000";

export const options = {
  stages: [
    { duration: "1m", target: 100 },
    { duration: "2m", target: 500 },
    { duration: "2m", target: 1000 },
    { duration: "1m", target: 0 },
  ],
  thresholds: {
    http_req_failed: ["rate<0.01"],   // <1% errors (availability SLO)
    http_req_duration: ["p(95)<300"], // p95 < 300ms (latency SLO)
  },
};

export default function () {
  check(http.get(`${BASE}/health`), { "200": (r) => r.status === 200 });
  sleep(0.2);
}

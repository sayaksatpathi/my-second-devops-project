import http from "k6/http"; import { check } from "k6";
export const options = { vus: 1, duration: "10s", thresholds: { http_req_failed: ["rate<0.01"] } };
export default function () { check(http.get(`${__ENV.TARGET}/health`), { "200": r => r.status === 200 }); }

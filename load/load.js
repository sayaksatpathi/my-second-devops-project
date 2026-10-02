import http from "k6/http"; import { check, sleep } from "k6";
export const options = {
  stages: [ {duration:"20s",target:30}, {duration:"40s",target:30}, {duration:"10s",target:0} ],
  thresholds: { http_req_failed: ["rate<0.15"], http_req_duration: ["p(95)<500"] },
};
export default function () { check(http.get(`${__ENV.TARGET}/work?max_ms=100`), {"ok":r=>r.status===200}); sleep(0.1); }

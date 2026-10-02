import http from "k6/http"; import { sleep } from "k6";
export const options = { stages: [ {duration:"20s",target:100}, {duration:"30s",target:300}, {duration:"10s",target:0} ] };
export default function () { http.get(`${__ENV.TARGET}/work?max_ms=50`); sleep(0.05); }

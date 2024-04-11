import http from 'k6/http';
import { sleep, check } from 'k6';

export let options = {
  // vus: __ENV.VUS || 10,
  // duration: __ENV.DURATION || '30s',
  stages: [
    { duration: '20s', target: __ENV.VUS || 10 }, // Ramp up to 100 users over 2 minutes
    { duration: __ENV.DURATION || '30s', target: __ENV.VUS || 10 }, // Ramp up to 100 users over 2 minutes
  ],
  insecureSkipTLSVerify: true,
};

export default function () {
  let targetUrl = __ENV.URL || 'http://localhost';

  let params = {
    headers: {
      'Connection':  __ENV.CONNECTION || 'close'
    }
  };

  // Unique identifier for each request
  let uniqueParam = `i=${__VU}-${__ITER}&connection=${__ENV.CONNECTION}`;

  // Do the request
  let response = http.get(`${targetUrl}?${uniqueParam}`, params);
  check(response, { 'status was 200': (r) => r.status == 200 });

  let sleepDuration = parseFloat(__ENV.SLEEP) || 1;
  sleep(sleepDuration);
}


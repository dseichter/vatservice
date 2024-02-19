import http from 'k6/http';
import exec from 'k6/execution';
import test from 'k6/execution';

const bzst_ok = JSON.parse(open('payloads/bzst_ok.json'));
const hmrc_ok = JSON.parse(open('payloads/hmrc_ok.json'));
const vies_ok = JSON.parse(open('payloads/vies_ok.json'));

export const options = {
  // A number specifying the number of VUs to run concurrently.

  // A string specifying the total duration of the test run.
  //duration: '30s',

  scenarios: {
    bzst: {
      executor: 'per-vu-iterations',
      exec: 'bzst',
      vus: 1,
      iterations: 1,
    },
    hmrc: {
      executor: 'per-vu-iterations',
      exec: 'hmrc',
      vus: 1,
      iterations: 1,
    },
    vies: {
      executor: 'per-vu-iterations',
      exec: 'vies',
      vus: 1,
      iterations: 1,
    }

  }

};

// The function that defines VU logic.
//
// See https://grafana.com/docs/k6/latest/examples/get-started-with-k6/ to learn more
// about authoring k6 scripts.
//
export function bzst() {
  const url = 'https://vat.erpware.co/v1/validate'

  const payload = JSON.stringify(bzst_ok);

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const res = http.post(url, payload, params);
  console.log(res.status, res.json().foreignvat)

  if (
    res.status != 200
  ) {
    exec.test.abort();
  }
}

export function hmrc() {
  const url = 'https://vat.erpware.co/v1/validate'

  const payload = JSON.stringify(hmrc_ok);

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const res = http.post(url, payload, params);
  console.log(res.status, res.json().foreignvat)

  if (
    res.status != 200
  ) {
    exec.test.abort();
  }
}

export function vies() {
  const url = 'https://vat.erpware.co/v1/validate'

  const payload = JSON.stringify(vies_ok);

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const res = http.post(url, payload, params);
  console.log(res.status, res.json().foreignvat)

  if (
    res.status != 200
  ) {
    exec.test.abort();
  }
}

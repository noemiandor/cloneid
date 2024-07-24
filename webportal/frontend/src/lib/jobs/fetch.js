import { decoderesponse } from '../js/misc';
import { fetchUrl } from '../fetchdata/fetchUrl';


export async function fetch_retrieveJob(p) {
  p.action = 'retrieve';
  p.action = 'r';
  const j = await fetchUrl('/api/jobs', 'get', p)
    .then(async (res) => {
      const r = await res.json();
      const data = r.data;
      return data;
    })
    .catch(async (e) => {
      console.log('e', e);
    });
  return j;
}

export async function fetch_publishJob(p) {
  p.action = 'publish';
  p.i = (new Date()).getTime();
  p.p = JSON.stringify(p.p);
  const j = await fetchUrl('/api/jobs', 'get', p)
    .then(async (res) => {
      const r = await res.json();
      return r.data;
    })
    .catch(async (e) => {
      console.log('fetch_publishJob', e);
    });
  return j;
}

export async function fetch_afianswer(p) {
  p.action = 'afianswer';
  await fetchUrl('/api/jobs', 'get', p);
}

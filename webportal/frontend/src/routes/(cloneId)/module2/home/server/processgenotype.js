import { BACKENDHOST, BACKENDHOST_DOCKER, BACKENDPORT, BACKENDPORT_DOCKER, SPSTATS_DIR } from '$env/static/private';
import { fetchUrl } from '@/lib/fetchdata/fetchUrl';
/**
 * @param {Request} request
 */
export async function processgenotype(request)
{

  const formdata = await request.formData();
  const destination = SPSTATS_DIR;
  const timeStamp = formdata.get("timestamp");
  const userHash = formdata.get("userhash");
  const perspective = formdata.get("perspective");
  const cellline = formdata.get("cellline");
  const cleanup = formdata.get("cleanup");
  console.log("timestamp", timeStamp);
  console.log("userhash", userHash);
  console.log("perspective", perspective);
  console.log("cellline", cellline);
  console.log("cleanup", cleanup);
  const size = 142;
  const name = 'SPSTATS';
  const index = '01';
  const file = cellline;

  let hostUrl = '';
  if (process.env.DOCKERNAME) {
    hostUrl = 'http://' + BACKENDHOST_DOCKER + ':' + BACKENDPORT_DOCKER + '/spstats';
  } else {
    hostUrl = 'http://' + BACKENDHOST + ':' + BACKENDPORT + '/spstats';
  }

  let q =
    hostUrl + '?' +
    [
      'size=' + encodeURIComponent(size),
      'name=' + encodeURIComponent(name),
      'index=' + encodeURIComponent(index),
      'timestamp=' + encodeURIComponent(timeStamp?.toString()),
      'userhash=' + encodeURIComponent(userHash?.toString()),
      'file=' + encodeURIComponent(file),
      'perspective=' + encodeURIComponent(perspective),
      'destination=' + encodeURIComponent(destination),
      'cleanup=' + encodeURIComponent(cleanup),
    ].join('&');

  console.log(q);

const par = {
size: size,
name: name,
index: index,
timestamp: timeStamp?.toString(),
userhash: userHash?.toString(),
file: file,
perspective: perspective,
destination: destination,
cleanup: cleanup,
cellline: cellline
}
  const result = await fetchUrl(hostUrl, 'get', par)
    .then(async (res) => {
      const x = await res.json();
      return x;
    })
    .catch((e) => {
      throw e;
    });

      console.log(result);
  return { result: JSON.stringify(result) };
}
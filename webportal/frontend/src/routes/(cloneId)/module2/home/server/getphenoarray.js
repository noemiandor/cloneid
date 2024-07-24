import { CELLPOS_DIR } from '$env/static/private';
import fs from "node:fs";
import { normalisePathFromComponents } from "./misc";

/**
 * @param {Request} request
 */
export async function getphenoarray(request)
{
  let d = {};
  for (const [k, v] of await request.formData()) {
    d[k] = v;
  }
  let srcpath = normalisePathFromComponents([CELLPOS_DIR, 'imagesets', d.s]);
  let dstpath = normalisePathFromComponents([CELLPOS_DIR, d.h, d.t]);
  const log = normalisePathFromComponents([srcpath, 'processed.log']);
  const alreadyProcessed = fs.existsSync(log);
  const srcoutput = normalisePathFromComponents([srcpath, 'output']);
  const dstoutput = normalisePathFromComponents([dstpath, 'output']);
  const srcimages = normalisePathFromComponents([srcoutput, 'Images']);
  const stdoutfile = normalisePathFromComponents([srcpath, 'stdout.txt']);
  const stderrfile = normalisePathFromComponents([srcpath, 'stderr.txt']);
  const notififile = normalisePathFromComponents([srcpath, 'notification.txt']);
  const processedf = normalisePathFromComponents([srcpath, 'processed.dat']);

  if (fs.existsSync(processedf)) {
    const ls3 = JSON.parse(fs.readFileSync(processedf).toString());
    return {
      h: d.h, t: d.t, p: dstpath, n: d.imageid, di: d.i, dp: d.p,
      state: 'getphenoarray', action: 'processphenotype',
      ls: JSON.stringify(ls3),
    };
  }
  let r = ({ ended: d.step == 300 ? true : false, step: `@@${d.step}@@`, notif: "39:notif" });
  return r;
}
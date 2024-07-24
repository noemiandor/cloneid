import { CELLPOS_DIR } from '$env/static/private';
import { fail } from "@sveltejs/kit";
import fs, { readFileSync } from "node:fs";
import { normalisePathFromComponents } from "./misc";


/**
 * @param {Request} request
 */
export async function processphenotypenotification(request)
{
      let d = {};
      for (const [k, v] of await request.formData()) {
        d[k] = v;
      }
      if (!(d.step && d.timestamp && d.userhash && d.imageid && d.from && d.media && d.flask && d.cellcount && d.event && d.dishsurfacearea && d.flaskitems && d.mediaitems && true)) {
        return fail(400, { missing: true });
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

      let notif = '';
      await new Promise((res) => setTimeout(res, 5000)); // Wait a while
      if (fs.existsSync(processedf)) {
        return ({ ended: true });
      }
      if (fs.existsSync(notififile)) {
        const nb = readFileSync(notififile);
        if (nb) {
          notif = nb.toString();
        }
      }
      let r = ({ ended: d.step == 300 ? true : false, step: `@@${d.step}@@`, notif: notif });
      return r;
    }
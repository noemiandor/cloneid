import { CELLPOS_DIR } from '$env/static/private';
import { fail } from '@sveltejs/kit';
import { datafromrequest, filessha, normalisePathFromComponents, savefilesin } from './misc.js';
/**
 * @param {Request} request
 */
export async function uploadallphenotypeimages(request) 
  {
    let r = await datafromrequest(request, ['t', 'h']);
    const missing = r.missing;
    const d = r.kv;
    if (missing?.length) {
      return fail(400, { missing: JSON.stringify(missing) });
    }
    if (!(d.f0 || d.f1 || d.f2 || d.f3)) {
      return fail(400, { missing: JSON.stringify(['f0', 'f1', 'f2', 'f3']) });
    }
    const s = await filessha([d.f0, d.f1, d.f2, d.f3]);
    d.i = normalisePathFromComponents([CELLPOS_DIR, 'imagesets', s, 'input']);
    d.p = normalisePathFromComponents([CELLPOS_DIR, d.h, d.t, 'input']);
    const c = await savefilesin(d);
    if (!(c.c >= 1 && c.c <= 4)) {
      return fail(400, { c: c, e: 'save', missing: true });
    }
    return ({ c: c.c, t: d.t, h: d.h, s: s });
  }

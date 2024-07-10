import { FIDINFO_DIR } from '$env/static/private';
import { sha512 } from "js-sha512";
import { writeFile } from 'node:fs/promises';
import { normalisePathFromComponents } from '../jobs/path';

/**
 * @param {{ toString: () => import("js-sha512").Message; }} id
 * @param {any} t
 * @param {any} p
 */

export async function createGcPayload(id, t, p) {
  const d = ({
    name: id,
    type: t,
    payload: p,
  });
  const s = sha512(id.toString());
  const f = normalisePathFromComponents([FIDINFO_DIR, `${s}.json`]);
  // fs.writeFileSync(f, JSON.stringify(d));
  await writeFile(f, JSON.stringify(d))
    // .then((x) => {
    //   console.log("createGcPayload X writeFile");
    // })
    .catch((e) => {
      console.log("createGcPayload E", e);
    })
    // .finally(() => {
    //   console.log("createGcPayload I", s, d);
    // })
    ;
  // console.log("createGcPayload", id, t, p, d, s);
  return s;
  // await zip(srcoutput, zipoutput);
}

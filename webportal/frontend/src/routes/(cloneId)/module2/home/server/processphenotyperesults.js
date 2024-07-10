import { CELLPOS_DIR } from '$env/static/private';
import { fail } from "@sveltejs/kit";
import fs, { readFileSync } from "node:fs";
import { calculateresult1, createZipResults, listDirWithImgSrc, normalisePathFromComponents } from "./misc.js";

/**
 * @param {Request} request
 */
export async function processphenotyperesults(request) {
    let d = {};
    for (const [k, v] of await request.formData()) {
        d[k] = v;
    }
    if (!(d.s)) {
        return fail(400, { missing: true });
    }
    const srcpath = normalisePathFromComponents([CELLPOS_DIR, 'imagesets', d.s]);
    const processedf = normalisePathFromComponents([srcpath, 'processed.dat']);
    const alreadyProcessed = (fs.existsSync(processedf));
    const srcoutput = normalisePathFromComponents([srcpath, 'output']);
    const srcimages = normalisePathFromComponents([srcoutput, 'Images']);

    if ((d.h && d.t)) {
        const dstpath = normalisePathFromComponents([CELLPOS_DIR, d.h, (d.t).toString()]);
        const dstoutput = normalisePathFromComponents([dstpath, 'output']);
        fs.cpSync(srcoutput, dstoutput, { recursive: true });
        await createZipResults(d, srcoutput, dstpath);
        // }
    }

    if (alreadyProcessed) {
        const ls3 = readFileSync(processedf).toString();
        return {
            s: d.s, h: d.h, t: d.t, ls: ls3
        };
    }

    const ls2 = await listDirWithImgSrc(srcimages, true, !false);
    const ls3 = JSON.stringify(Object.values(ls2));
    fs.writeFileSync(normalisePathFromComponents([srcpath, 'processed.log']), (new Date()).toUTCString(), { flag: "a+" });
    fs.writeFileSync(normalisePathFromComponents([srcpath, 'processed.dat']), ls3);
    return {
        s: d.s, h: d.h, t: d.t, ls: ls3
    };

}

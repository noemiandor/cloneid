import { CELLPOS_DIR } from '$env/static/private';
import { fail } from "@sveltejs/kit";
import fs, { existsSync, mkdirSync } from "node:fs";
import { createZipResults, listDirWithImgSrc, normalisePathFromComponents } from "./misc.js";


/**
 * @param {Request} request
 */
export async function pageServerSaveSeginfo(request) {
    let d = {};
    for (const [k, v] of await request.formData()) {
        d[k] = v;
    }
    if (!(d.g)) {
        return fail(400, { missing: true });
    }

    const glob = JSON.parse(d.g);
    const seginfo = glob['seginfo'];

    const srcimgset = normalisePathFromComponents([CELLPOS_DIR, 'imagesets', seginfo['s']]);
    const txidrsdir = normalisePathFromComponents([CELLPOS_DIR, seginfo.h, (seginfo.t).toString()]);
    const srcoutput = normalisePathFromComponents([srcimgset, 'output']);
    const srcimages = normalisePathFromComponents([srcoutput, 'Images']);
    const srcrsults = normalisePathFromComponents([srcimgset, 'results']);
    const txirsults = normalisePathFromComponents([txidrsdir, 'results']);

    if (!existsSync(srcrsults)) {
        mkdirSync(srcrsults, { recursive: true });
    }
    if (!existsSync(txirsults)) {
        mkdirSync(txirsults, { recursive: true });
    }

    const processedd = normalisePathFromComponents([srcrsults, 'seginfodata.json']);
    const processedi = normalisePathFromComponents([srcrsults, 'seginfoimgs.json']);
    const processedl = normalisePathFromComponents([srcrsults, 'seginfodate.log']);

    const processedt = normalisePathFromComponents([txirsults, 'seginfodata.json']);

    const nowdate = (new Date()).toUTCString();
    if (
        fs.existsSync(processedl) &&
        fs.existsSync(processedi) &&
        fs.existsSync(processedd) &&
        true
    ) {
        return {
            date: fs.readFileSync(processedl).toString(),
            data: fs.readFileSync(processedd).toString(),
            imgs: fs.readFileSync(processedi).toString(),
        };
    } else {
        const imgl = await listDirWithImgSrc(srcimages, true, true);
        const imgv = JSON.stringify(Object.values(imgl));
        fs.writeFileSync(processedl, nowdate, { flag: "a+" });
        fs.writeFileSync(processedd, d.g);
        fs.writeFileSync(processedi, imgv);
        fs.writeFileSync(processedt, d.g);
        await createZipResults(glob.seginfo, srcoutput, srcrsults);
        await createZipResults(glob.seginfo, srcoutput, txirsults);
        return {
            date: fs.readFileSync(processedl).toString(),
            data: fs.readFileSync(processedd).toString(),
            imgs: fs.readFileSync(processedi).toString(),
        };
    }
}

/**
 * @param {Request} request
 */
export async function pageServerSaveImgInfo(request) {
    let d = {};
    for (const [k, v] of await request.formData()) {
        d[k] = v;
    }
    if (!(d.s)) {
        return fail(400, { missing: true });
    }

    console.log("pageServerSaveImgInfo ", d);

    const srcimgset = normalisePathFromComponents([CELLPOS_DIR, 'imagesets', d.s]);
    const srcoutput = normalisePathFromComponents([srcimgset, 'output']);
    const srcimages = normalisePathFromComponents([srcoutput, 'Images']);
    const srcrsults = normalisePathFromComponents([srcimgset, 'results']);
    if (!existsSync(srcrsults)) {
        mkdirSync(srcrsults, { recursive: true });
    }
    const processedi = normalisePathFromComponents([srcrsults, 'seginfoimgs.json']);
    if (
        fs.existsSync(processedi) &&
        true
    ) {
        return {
            imgs: fs.readFileSync(processedi).toString(),
        };
    } else {
        const imgl = await listDirWithImgSrc(srcimages, true, true);
        const imgv = JSON.stringify(Object.values(imgl));
        fs.writeFileSync(processedi, imgv);
        return {
            imgs: fs.readFileSync(processedi).toString(),
        }
    };
}

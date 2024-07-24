import { CELLPOS_DIR, SQLPSWD, SQLSCHM, SQLUSER } from '$env/static/private';
import { runningInDocker } from "@/lib/mysql/runningInDocker";
import { createJbPayload, serverCreateJbPayload } from "@/lib/jobs/funcs.server.js";
import { fail } from "@sveltejs/kit";
import fs, { readFileSync } from "node:fs";
import { calculateresult1, createZipResults, listDirWithImgSrc, normalisePathFromComponents } from "./misc.js";
import { fetch_publishJob } from '@/lib/jobs/fetch.js';
import { sqlpswd, sqluser } from '@/lib/mysql/sqlinfo.js';
/**
 * @param {Request} request
 */
export async function processphenotype(request) {
    let d = {};
    for (const [k, v] of await request.formData()) {
        d[k] = v;
    }
    if (!(d.username && d.timestamp && d.userhash && (d.f0 || d.f1 || d.f2 || d.f3) && d.imageid && d.from && d.media && d.flask && d.cellcount && d.event && d.dishsurfacearea && d.flaskitems && d.mediaitems && d.waitforresult && true)) {
        return fail(400, { missing: true });
    }
    let srcpath = normalisePathFromComponents([CELLPOS_DIR, 'imagesets', d.s]);
    let dstpath = normalisePathFromComponents([CELLPOS_DIR, d.h, d.t]);
    const log = normalisePathFromComponents([srcpath, 'processed.log']);
    const processedf = normalisePathFromComponents([srcpath, 'processed.dat']);
    const alreadyProcessed = (fs.existsSync(processedf));

    process.env.SQLUSER = await sqluser(d.username);
    process.env.SQLPSWD = await sqlpswd(d.username);
    let transactionid = d.timestamp;
    transactionid = d.s;

    const backendhost = (runningInDocker() ? 'backend-conda-m2' : 'localhost');
    const backendhostcreds = 'root@' + backendhost;
    const backendhostport = runningInDocker() ? '22' : '2222';
    const RHost = "sql2";
    const RPort = 3306;

    const useJobPayload = true;
    const useDirectConection = !useJobPayload;

    if (useJobPayload) {
        const txid = (new Date()).getTime();
 
        const payload = [
            'Rscript', '--vanilla',
            '/opt/lake/data/cloneid/module02/data/scripts/R/IVU9.R',
            d.event, d.imageid, d.from, d.cellcount, d.timestamp, d.flask, d.media,
            "sql2", 3306, process.env.SQLUSER, process.env.SQLPSWD, SQLSCHM,
            CELLPOS_DIR, 'imagesets', transactionid, txid, 'ivu'
        ];

        const p = { spawn: payload };
        const jid = await serverCreateJbPayload('m2.cellpose', 'waiting', txid, p);
        return {i:jid.i};
    }

}

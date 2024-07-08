
import { watch } from 'fs';
import pkg from 'fs-extra';
import { existsSync } from "node:fs";
import { logmessage, logerror, extractJbPayload, listDir, normalisePathForPayload, normalisePathForAppJobs, normalisePathFromComponents, normalisePathForQueue } from "./server/misc.mjs";
import { spawnjob } from "./server/spawnjob.mjs";
const { moveSync } = pkg;

logmessage(["dw starting"])

async function processPayload(d, job, app, queue) {
    if (!job.endsWith('.json')) {
        return false;
    }
    const jp = normalisePathFromComponents([d, job]);
    const dq = normalisePathForPayload(app, 'done', job);
    const eq = normalisePathForPayload(app, 'error', job);
    if (!existsSync(jp)) {
        logmessage([app, queue, job, "removed"]);
        return false;
    }
    const id = (job.split(".json"))[0];
    const j = await extractJbPayload(d, id, app, queue);

    if (!(j && j.a)) return false;
    switch (j.a) {
        case 'm2.cellpose':
        case app:
            if (await spawnjob(app, queue, id, j)) {
                logmessage(["DONE", id, app, queue]);
                logmessage(["MOVING", jp, dq]);
                moveSync(jp, dq);
                return true;
            }else{
                logmessage(["ERROR", id, app, queue]);
                logmessage(["MOVING", jp, eq]);
                moveSync(jp, eq);
                return false;
            }
            break;
        default:
            return false;
    }
}
async function processQueue(qdir, list, app, queue) {
    let done = 0;
    while (list.length) {
        const l = list.length;
        const j = list.shift();
        logmessage(["QUEUED", j, l, "jobs"]);
        if (await processPayload(qdir, j, app, queue)) {
            done++;
        }
    }
    return done;
}

function enqueuwaitingdir(d) {
    const b = [];
    logmessage(["processwaitingdir ENQUEUE EXISTING WAITING", d]);
    const files = listDir(d);
    const lf = files.map((x) => { return x.name; }).filter((x) => { return x.endsWith('.json'); }).sort((a, b) => { return a.localeCompare(b); });
    lf.forEach((x) => { b.push(x); });
    return b;
}

async function processPayloadDir(dir, app, queue) {

    const qdir = normalisePathForQueue(app, queue);
    if (!existsSync(qdir)) {
        throw qdir;
    }

    let joblist = [];
    let totaljobs = 0;
    let donejobs = 0;

    joblist = enqueuwaitingdir(qdir);
    totaljobs = joblist.length;
    logmessage(["ADDING WATCH DIR:WAITING", qdir, "A =", totaljobs, joblist]);
    

    watch(qdir, async (e, f) => {
        if (f.endsWith('.json') && existsSync(qdir + '/' + f)) {
            if (!joblist.includes(f)) {
                joblist.push(f);
                logmessage(["QUEUING", app, queue, f, e, totaljobs++, joblist.length]);
            }
        }
    });
    while (true) {
        donejobs += await processQueue(qdir, joblist, app, queue);
        logmessage(["DONE/TOTAL:", donejobs, totaljobs]);
        await new Promise((res) => setTimeout(res, 5000));
    }
    ;
}

const dir = normalisePathForAppJobs();
const app = 'm2.cellpose';
const queue = 'waiting';
await processPayloadDir(dir, app, queue);

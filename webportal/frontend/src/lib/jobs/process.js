import pkg from 'fs-extra';
const { moveSync} = pkg;
import { existsSync } from "node:fs";
import { extractJbPayload, logmessage, normalisePathForPayload, normalisePathFromComponents } from "./path.js/index.js";
import { spawn } from "./spawn.mjs";

export async function processPayload(d, job, app, queue) {
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
            if (await spawn(app, queue, id, j)) {
                logmessage(["DONE", id, app, queue]);
                logmessage(["MOVING", jp, dq]);
                moveSync(jp, dq);
                return true;
            } else {
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

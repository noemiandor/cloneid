import { JOBINFO_DIR } from '$env/static/private';
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { listDir, listDirChronologically, normalisePathFromComponents } from "./path.js";
// import { moveSync } from 'fs-extra';
import pkg from 'fs-extra';
const { moveSync, removeSync } = pkg;

/**
 * @param {string} f
 */
function archiveNameFor(f) {
    return [(new Date()).getTime().toString(), '_', f].join('');
}
/**
 * @param {string} app
 * @param {string} id
 */
export function getPushedEvents(app, id) {
    const pushedDir = normalisePathFromComponents([JOBINFO_DIR, app, 'spawn', id, 'pushed']);
    const pulledDir = normalisePathFromComponents([JOBINFO_DIR, app, 'spawn', id, 'pulled']);
    const pushedList = listDirChronologically(pushedDir)
    return (pushedList);
}


/**
 * @param {string} app
 * @param {string} id
 * @param {string} fni
 */
export function readAndMoveToPulled(app, id, fni) {
    const pushedDir = normalisePathFromComponents([JOBINFO_DIR, app, 'spawn', id, 'pushed']);
    const pulledDir = normalisePathFromComponents([JOBINFO_DIR, app, 'spawn', id, 'pulled']);
    const fpi = normalisePathFromComponents([pushedDir, fni]);
    const fpo = normalisePathFromComponents([pulledDir, fni]);
    if (existsSync(fpi)) {
        const content = readFileSync(fpi).toString();
        moveSync(fpi, fpo);
        return (content);
    }
    return null;
}

/**
 * @param {string} app
 * @param {string} id
 * @param {string} fni
 */
export function readAndArchive(app, id, fni) {
    const fpi = normalisePathFromComponents([JOBINFO_DIR, app, 'spawn', id, fni]);
    const fpo = normalisePathFromComponents([JOBINFO_DIR, app, 'spawn', id, archiveNameFor(fni)]);
    if (existsSync(fpi)) {
        const content = readFileSync(fpi).toString();
        moveSync(fpi, fpo);
        return (content);
    }
    return null;
}

/**
 * @param {string} app
 * @param {string} id
 * @param {string} fni
 */
export function readAndKeep(app, id, fni) {
    const fpi = normalisePathFromComponents([JOBINFO_DIR, app, 'spawn', id, fni]);
    const fpo = normalisePathFromComponents([JOBINFO_DIR, app, 'spawn', id, archiveNameFor(fni)]);
    if (existsSync(fpi)) {
        const content = readFileSync(fpi).toString();
        return (content);
    }
    return null;
}




/**
 * @param {string} app
 * @param {string} id
 */
export function ping(app, id) {
    const pingDir = normalisePathFromComponents([JOBINFO_DIR, app, 'spawn', id]);
    const pingFile = normalisePathFromComponents([pingDir, 'ping.txt']);
    if (existsSync(pingDir)) {
        const d = ({ date: (new Date()).getTime() })
        writeFileSync(pingFile, JSON.stringify(d));
        return 0;
    } else {
        console.log("NO SPAWN", pingDir);
        return -1;
    }
}

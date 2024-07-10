import { SQLUSRS_DIR } from '$env/static/private';


import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { normalisePathFromComponents } from '../jobs/path';


import pkg from 'fs-extra';
const { removeSync } = pkg;

export async function createUser(u, p) {
    if (!(u && p)) {
        throw "createUser";
    }
    console.log("createUser", "U", u, "P", p)
    const t = (new Date()).getTime();
    const j = ({
        u: u,
        t: t,
        p: p,
    });
    const jd = normalisePathFromComponents([SQLUSRS_DIR, u]);
    mkdirSync(jd, { recursive: true });
    const jf = normalisePathFromComponents([jd, 'info.json']);
    writeFileSync(jf, JSON.stringify(j));
    return j;
}

export async function deleteUser(u) {
    if (!(u)) {
        throw "deleteUser";
    }
    console.log("deleteUser", "U", u)
    const jd = normalisePathFromComponents([SQLUSRS_DIR, u]);
    if (existsSync(jd)) {
        removeSync(jd);
    }
}

export async function retrieveUser(u) {
    console.log("retrieveUser", "U", u)
    if (!(u)) {
        throw "retrieveUser";
    }
    const jd = normalisePathFromComponents([SQLUSRS_DIR, u]);
    const jf = normalisePathFromComponents([jd, 'info.json']);
    if (existsSync(jf)) {
        const d = readFileSync(jf).toString();
        const j = JSON.parse(d);
        return j;
    }
    return null;
}

export async function validateUser(u, p) {
    if (!(u && p)) {
        throw "validateUser";
    }
    console.log("validateUser", "U", u, "P", p)
    const jd = normalisePathFromComponents([SQLUSRS_DIR, u]);
    const jf = normalisePathFromComponents([jd, 'info.json']);
    if (existsSync(jf)) {
        const d = readFileSync(jf).toString();
        const j = JSON.parse(d);
        return (u === j.u && p === j.p);
    }
    return null;
}


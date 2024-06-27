import fs, { existsSync, readFileSync, mkdirSync } from "node:fs";
import { mkdir, readFile, writeFile } from 'node:fs/promises';

/**
 * @param {[string]} a
 */
export function logmessage(a) {
  if (!(a && a.length)) return;
  console.log(["INFO", ...a].join('::'));
}
/**
 * @param {[string]} a
 */
export function logerror(a) {
  if (!(a && a.length)) return;
  console.error(a.join('::'));
}


/**
 * @param {string} id
 * @param {string} t
 * @param {string} s
 * @param {any} p
 */
export async function extractJbPayload(dir, id, app, queue) {
  if (!(id && dir)) {
    throw "extractJbPayload";
  }
  const jidf = normalisePathFromComponents([dir, `${id}.json`]);
  if (existsSync(jidf)) {
    const data = readFileSync(jidf);
    const jid = JSON.parse(data.toString());
    // console.log("extractJbPayload", jid);
    return jid;
  } else {
    return null;
  }
}



/**
 * @param {fs.PathLike} dirpath
 */
export function listDir(dirpath) {
  if (!fs.existsSync(dirpath)) return [];
  return fs.readdirSync(dirpath, {
    withFileTypes: true,
    recursive: true
  });
}


/**
 * @param {string[]} a
 */
export function normalisePathFromComponents(a, retainFirstSlash = true) {
  let slash = '';
  if (retainFirstSlash) {
    if (a[0].startsWith('/')) {
      slash = '/';
    }
  }
  return slash + a.map((p) => {
    if (!p) return '';
    if (p === '') return '';
    let q = p.trim();
    q = q.replace(/^\/+|\/+$/g, '');
    return q;
  }).join('/');
}


export function normalisePathForDataLake(d) {
  return process.env.DATALKE_DIR;
}

export function normalisePathForFileInfoDir(d) {
  return process.env.FIDINFO_DIR;
}

export function normalisePathForJobInfoDir(d) {
  return process.env.JOBINFO_DIR;
}

export function normalisePathForSPStatsDir(d) {
  return process.env.SPSTATS_DIR;
}

export function normalisePathForCellposeDir(d) {
  return process.env.CELLPOS_DIR;
}








export function normalisePathForAppJobs(d) {
  return process.env.PAYLOADDIR;
}

export function normalisePathForApp(a) {
  return normalisePathFromComponents([normalisePathForAppJobs(), a]);
}

export function normalisePathForQueue(a, q) {
  return normalisePathFromComponents([normalisePathForApp(a), q]);
}

export function normalisePathForPayload(a, q, i) {
  if (i.endsWith('.json')) {
    return normalisePathFromComponents([normalisePathForQueue(a, q), i]);
  } else {
    return normalisePathFromComponents([normalisePathForQueue(a, q), `${i}.json`]);
  }
}
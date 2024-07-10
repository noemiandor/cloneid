import fs from "node:fs";

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
 * @param {fs.PathLike} dirpath
 * @returns {string[]}
 */
export function listDirChronologically(dirpath) {
  if (!fs.existsSync(dirpath)) {
    return [];
  }
  const files = fs.readdirSync(dirpath).map(filename => {
    const filepath = `${dirpath}/${filename}`;
    const stat = fs.statSync(filepath);
    return { filename, mtime: stat.mtime.getTime() };
  });

  const sortedFiles = files
    .filter(file => !fs.statSync(`${dirpath}/${file.filename}`).isDirectory())
    .sort((a, b) => a.mtime - b.mtime)
    .map(file => file.filename);

  return sortedFiles;
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
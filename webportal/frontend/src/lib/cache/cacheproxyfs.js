<<<<<<< HEAD
import { CACHE, USECACHE, USEDB, USEFS } from '$env/static/private';
import * as JSsha512 from 'js-sha512';
import { Buffer } from 'node:buffer';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { count } from '../js/count';

// Determine the usage of different storage options based on environment variables
let useDB = (USEDB !== 'NO'); // Use database if USEDB is not set to 'NO'
let useCache = (USECACHE !== 'NO'); // Use cache if USECACHE is not set to 'NO'

let fromFs = (USEFS !== 'NO'); // Read from filesystem if USEFS is not set to 'NO'

let fromShard = useCache;
let toShard = useCache;

if (false) {
    useDB = true;
    useCache = false;
    fromShard = false;
    toShard = false;
}

/**
 * Generate a cache key based on input arguments.
 * @param {any[]} args
 * @returns {string}
 */
export function cachedKey(args) {
    const shard = `${args.join('-')}`; // Concatenate arguments with hyphens
    const key = JSsha512.sha512(shard); // Hash the concatenated string
=======
import { CACHE } from '$env/static/private';
import { Buffer } from 'node:buffer';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import * as JSsha512 from 'js-sha512';
import { count } from '../js/count';
import { compressToUTF16, decompressFromUTF16 } from 'async-lz-string';

/**
 * @param {any[]} args
 */
export function cachedKey(args) {
    const shard = `${args.join('-')}`
    const key = JSsha512.sha512(shard);
>>>>>>> master
    return shard;
}

/**
<<<<<<< HEAD
 * Load cached data based on input arguments.
 * @param {any[]} args - Arguments used to identify the cache entry.
 * @returns {Promise<any>}
 */
export async function loadCachedFromArgs(args) {
    const key = cachedKey(args);
    const cachedRows = await getShard(key);
    if (cachedRows && count(cachedRows) >= 0) {
        return cachedRows;
    } else if (!cachedRows) {
        console.log("CACHEPROXYFS::LOADCACHE::NOTFOUND::", key, args);
=======
 * @param {any[]} args
 */
export async function loadCachedFromArgs(args) {
    const key = cachedKey(args);
    const rows = await getShard(key);
    if (rows && count(rows) >= 0) {
        return rows;
    } else if (!rows) {
        console.log("CACHEPROXYFS::LOADCACHEDFROMARGS::NULL::", key, args);
        return null;
>>>>>>> master
    }
}

/**
<<<<<<< HEAD
 * Load cached data based on a specific key.
 * @param {string} key - The cache key.
 * @returns {Promise<any>}
 */
export async function loadCachedFromKey(key) {
    const cachedRows = await getShard(key);
    if (cachedRows && count(cachedRows) >= 0) {
        return cachedRows;
    } else if (!cachedRows) {
        console.log("CACHEPROXYFS::LOADCACHE::NULL::", key);
    }
}

/**
 * Store data in the cache with a specific key.
 * @param {string} key - The cache key.
 * @param {any} val - The value to be stored.
 * @returns {Promise<boolean>}
=======
 * @param {string} key
 * @param {any} val
>>>>>>> master
 */
export async function storeCached(key, val) {
    return await saveShard(key, val);
}

/**
<<<<<<< HEAD
 * Generate a hash key for a given string.
 * @param {string} s - The input string to hash.
 * @returns {string} The resulting hash key.
=======
 * @param {string} s
>>>>>>> master
 */
export function shardKey(s) {
    return JSsha512.sha512(s);
}

/**
<<<<<<< HEAD
 * Generate paths and keys related to a given shard.
 * @param {string} s
 * @returns {object}
=======
 * @param {string} s
>>>>>>> master
 */
export function shardPathx(s) {
    const k = shardKey(s);
    const d = k.substring(0, 2);
    const ext = '.json';
<<<<<<< HEAD
    const p = `${CACHE}${d}/${k}${ext}`;
    return {
        "dir": CACHE,
        "shard": `${CACHE}${d}/`,
        "key": k,
        "ext": ext,
        "path": p,
        "pref": d,
    }
}

/**
 * Save data to a shard based on a key.
 * @param {string} q
 * @param {any} v
 * @returns {Promise<boolean>}
 */
export async function saveShard(q, v) {
    if (!toShard) return null;
=======
    const p = CACHE + d + '/' + k + ext;
    return {
        "dir": CACHE,
        "shard": CACHE + d + '/',
        "key": k,
        "ext": ext,
        "path": p,
    }
}


function jsonify(obj) {
    if (typeof obj === 'number') {
        return obj;
    }
    if (typeof obj !== 'object' || obj === null || obj instanceof Date || obj instanceof RegExp || typeof obj === 'string') {
        let x = '';
        try {
            x = JSON.stringify(obj);
        } catch (error) {
            console.log("ERROR1", error, obj)
        }
        return x;
    }

    if (Array.isArray(obj)) {
        return  '[ ' + obj.map((item) => jsonify(item)).join(', ') + ' ]';
    }

    const resultA = [];
    for (const key in obj) {
        if (Object.hasOwnProperty.call(obj, key)) {
            resultA.push(`"${key}":${jsonify(obj[key])}`);
        }
    }
    return  '{ ' + resultA.join(', ') + ' }';
}


function parseJson(jsonString) {
    return JSON.parse(jsonString, (key, value) => {
        if (typeof value === 'string' && value.startsWith('{') && value.endsWith('}')) {
            return parseJson(value); // Recursively parse nested objects
        } else
            if (typeof value === 'string' && value.startsWith('[') && value.endsWith(']')) {
                return parseJson(value); // Recursively parse nested objects
            } else
                if (typeof value === 'string' && value.startsWith('"') && value.endsWith('"')) {
                    return parseJson(value); // Recursively parse nested objects
                } else
                    return value;
    });
}


const stringifyJSON = data => {
    if (data === undefined)
        return undefined
    else if (data === null)
        return 'null'
    else if (data.constructor === String)
        return '"' + data.replace(/"/g, '\\"') + '"'
    else if (data.constructor === Number)
        return String(data)
    else if (data.constructor === Boolean)
        return data ? 'true' : 'false'
    else if (data.constructor === Array)
        return '[ ' + data.reduce((acc, v) => {
            if (v === undefined)
                return [...acc, 'null']
            else
                return [...acc, stringifyJSON(v)]
        }, []).join(', ') + ' ]'
    else if (data.constructor === Object)
        return '{ ' + Object.keys(data).reduce((acc, k) => {
            if (data[k] === undefined)
                return acc
            else
                return [...acc, stringifyJSON(k) + ':' + stringifyJSON(data[k])]
        }, []).join(', ') + ' }'
    else
        return '{}'
}
const test = data => {
    console.log("DATA", data);
    const sdata = stringifyJSON(data);
    console.log("SDATA", sdata);
    const psdata = JSON.parse(sdata)
    return console.log("PSDATA", psdata)
}


/**
 * @param {string} q 
 * @param {any} v
 */
export async function saveShard(q, v) {
>>>>>>> master

    let error = false;
    const px = shardPathx(q);
    try {
        const createDir = await mkdir(px["shard"], { recursive: true });
    } catch (err) {
        console.error(err);
        console.log("catch::saveShard::CREATED", px["shard"], q);
        error = true;
    }
    if (!error) {
<<<<<<< HEAD
        const obj = { "k": q, "v": v };
        const d = JSON.stringify(obj);
        const data = new Uint8Array(Buffer.from(d));
        try {
            await writeFile(px["path"], data, { encoding: 'utf8' });
            console.log(`writeFile(q, v)::${q}::${px["path"]}`);
=======
        const obj = ({ "k": q, "v": v });
        const d = jsonify(obj);
        const data = new Uint8Array(Buffer.from(d));
        try {
            const bytes = await writeFile(px["path"], data, { encoding: 'utf8' });
            const xx = await getShard(q);
>>>>>>> master
        } catch (err) {
            console.log(`CATCH::writeFile(q, v) ${q} ${px["path"]}`);
            error = true;
        }
    }
    return !error;
<<<<<<< HEAD
}

/**
 * Retrieve data from a shard based on a key.
 * @param {string} q - The key associated with the shard.
 * @returns {Promise<any>} A promise that resolves to the retrieved value, if any.
 */
export async function getShard(q) {
    if (!fromShard) return null;
=======
};

/**
 * @param {string} q 
 */
export async function getShard(q) {
>>>>>>> master

    let error = false;
    const px = shardPathx(q);
    let data;
<<<<<<< HEAD
    if (fromFs) {
        try {
            data = await readFile(px["path"], { encoding: 'utf8' });
        } catch (err) {
            error = true;
        }
    }
    if (error) {
        return null;
    }
    const v = JSON.parse(data);
    if (v && v.k == q) {
        return v.v;
    }
    return null;
}
=======
    try {
        data = await readFile(px["path"], { encoding: 'utf8' });
    } catch (err) {
        if(err.errno !== -2) console.log('CACHE::readFile::ERROR getShard(q)', q, px, err);
        return null;
    }
    try {
        const v = parseJson(data);
        if (v && v.k === q) {
            return v.v;
        } else {
            console.log('CACHE::readFile::JSON getShard(q)::NOT EQUAL KEY::', q, px, v, v.k);
        }
    } catch (error) {
        console.log('CACHE::GETSHARD::readFile::JSONPARSE::ERROR', q, px, error);
    }
    return null;
};
>>>>>>> master

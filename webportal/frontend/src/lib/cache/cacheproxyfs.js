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
    return shard;
}

/**
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
    }
}

/**
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
 */
export async function storeCached(key, val) {
    return await saveShard(key, val);
}

/**
 * Generate a hash key for a given string.
 * @param {string} s - The input string to hash.
 * @returns {string} The resulting hash key.
 */
export function shardKey(s) {
    return JSsha512.sha512(s);
}

/**
 * Generate paths and keys related to a given shard.
 * @param {string} s
 * @returns {object}
 */
export function shardPathx(s) {
    const k = shardKey(s);
    const d = k.substring(0, 2);
    const ext = '.json';
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
        const obj = { "k": q, "v": v };
        const d = JSON.stringify(obj);
        const data = new Uint8Array(Buffer.from(d));
        try {
            await writeFile(px["path"], data, { encoding: 'utf8' });
            console.log(`writeFile(q, v)::${q}::${px["path"]}`);
        } catch (err) {
            console.log(`CATCH::writeFile(q, v) ${q} ${px["path"]}`);
            error = true;
        }
    }
    return !error;
}

/**
 * Retrieve data from a shard based on a key.
 * @param {string} q - The key associated with the shard.
 * @returns {Promise<any>} A promise that resolves to the retrieved value, if any.
 */
export async function getShard(q) {
    if (!fromShard) return null;

    let error = false;
    const px = shardPathx(q);
    let data;
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
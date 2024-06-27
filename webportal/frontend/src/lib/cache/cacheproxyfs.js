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
    return shard;
}

/**
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
    }
}

/**
 * @param {string} key
 * @param {any} val
 */
export async function storeCached(key, val) {
    return await saveShard(key, val);
}

/**
 * @param {string} s
 */
export function shardKey(s) {
    return JSsha512.sha512(s);
}

/**
 * @param {string} s
 */
export function shardPathx(s) {
    const k = shardKey(s);
    const d = k.substring(0, 2);
    const ext = '.json';
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
        const obj = ({ "k": q, "v": v });
        const d = jsonify(obj);
        const data = new Uint8Array(Buffer.from(d));
        try {
            const bytes = await writeFile(px["path"], data, { encoding: 'utf8' });
            const xx = await getShard(q);
        } catch (err) {
            console.log(`CATCH::writeFile(q, v) ${q} ${px["path"]}`);
            error = true;
        }
    }
    return !error;
};

/**
 * @param {string} q 
 */
export async function getShard(q) {

    let error = false;
    const px = shardPathx(q);
    let data;
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
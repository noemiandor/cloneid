import { getShard, saveShard } from '$lib/cache/cacheproxyfs';
import { Perspectives } from '$lib/cloneid/core/utils/Perspectives';
import { Manager } from "@/lib/cloneid/cloneid/Manager";
import compare from 'just-compare';

import { TMP } from '$env/static/private';
import { Buffer } from 'node:buffer';
import { mkdir, writeFile } from 'node:fs/promises';

import { count } from '../count';
import { _view } from './umapjs';

const dir = TMP;

export function savePath(n, ext) {
    const p = dir + '/' + n + ext;
    return {
        dir: dir,
        shard: dir + '/',
        ext: ext,
        path: p
    };
}

/**
 * @param {string} q
 * @param {any} v
 */
export async function saveFile(n, d, e = '.csv') {
    let error = false;
    const px = savePath(n, e);
    try {
        const createDir = await mkdir(px['shard'], { recursive: true });
    } catch (err) {
        console.error(err);
        error = true;
    }
    if (error) return !error;
    const data = new Uint8Array(Buffer.from(d));
    try {
        await writeFile(px['path'], data);
    } catch (err) {
        error = true;
    }
    return !error;
}


/**
 * @param {any} subClones
 */
export function pie(subClones) {

    let pG = subClones;
    let ploci = [];
    let cloneindex = 0;
    let columns = {};
    let membership = {};
    let rows = {};
    let headers = {};
    let matrix = {};
    let rowheader = [];
    let columnheader = [];
    for (const [subClone, subProfiles] of Object.entries(subClones)) {
        for (const [subProfile, lociAndValues] of Object.entries(subProfiles)) {
            for (const [lociOrValue, values] of Object.entries(lociAndValues)) {
                let index = 0;
                if (lociOrValue == 'loci') {
                    if (!compare(values, ploci)) {
                        headers['row'] = values;
                        ploci = values;
                    }
                }
                if (lociOrValue == 'values') {
                    columns[subProfile] = values;
                    membership[subProfile] = subClone;
                    columnheader.push(subProfile);
                }
            }
        }
    }
    headers['column'] = columnheader;
    matrix = { columns: columns, headers: headers };
    let clonemembershipG = [];
    for (const subProfile in subClones) {
        const subProfile_keys = Object.keys(subProfile);
        Object.keys(subClones[subProfile]).forEach((key) => {
            clonemembershipG[key] = subProfile;
        })
    }

    let clonesizesG = {};
    for (const [key, value] of Object.entries(pG)) {
        clonesizesG[key] = Object.keys(value).length;
    };

    let cellcountG = Object.values(clonesizesG).reduce((total, size) => total + size, 0);

    let nameG = [...new Set(Object.values(clonemembershipG))];

    return clonesizesG;
}


/**
 * @param {any} subClones
 */
export function heatmap(subClones) {
    let rows = [];
    let rowheader = null;

    const subClones_entries = Object.entries(subClones);
    for (const [subClone, subProfiles] of subClones_entries) {

        if (!rowheader) {
            rowheader = { loci: subProfiles.loci };
        }
        let row = {};
        row['subClone'] = subClone;
        row['values'] = subProfiles.values;
        rows.push(row);
    }

    const rowscount = count(rows);
    const colscount = count(rowheader.loci);;
    var tmpDATA = new Array(rowscount)
    for (let j = 0; j < rowscount; j++) {
        let row = {};
        row['subClone'] = rows[j].subClone;
        for (let i = 0; i < colscount; i++) {
            row[rowheader?.loci[i]] = rows[j].values[i];
        }
        tmpDATA[j] = row;
    }
    return ({ coln: rowheader.loci, rown: rows.map((x) => { return x.subClone; }), data: rows.map((x) => { return x.values; }) });
}




/**
 * @param {any} subClones
 */
export function umap(subClones) {
    let ploci = [];
    let columns = {};
    let membership = {};
    let headers = {};
    let columnheader = [];
    let clonemembership = [];
        for (const [subClone, subProfiles] of Object.entries(subClones)) {
            if (subProfiles && Object.keys(subProfiles) && Object.keys(subProfiles).length)
                for (const [subProfile, lociAndValues] of Object.entries(subProfiles)) {
                    for (const [lociOrValue, values] of Object.entries(lociAndValues)) {
                        if (lociOrValue == 'loci') {
                            if (!compare(values, ploci)) {
                                headers['row'] = values;
                                ploci = values;
                            }
                        }
                        if (lociOrValue == 'values') {
                            columns[subProfile] = values;
                            membership[subProfile] = subClone;
                            columnheader.push(subProfile);
                            clonemembership.push(subClone);
                        }
                    }
                }
        }
    headers['column'] = columnheader;

    const colscount = columnheader.length;

    var tmpDATA = new Array(colscount)
    if (headers && headers.row && headers.row.length) {
        const rowscount = headers.row.length;
        for (let j = 0; j < colscount; j++) {
            let row = {};
            row['subClone'] = membership[columnheader[j]];
            row['subProfile'] = columnheader[j];
            for (let i = 0; i < rowscount; i++) {
                row[headers.row[i]] = columns[columnheader[j]][i];
            }
            tmpDATA[j] = row;
        }
    }

    return _view("", 100, 100, tmpDATA);
}

export async function genomicProfileForSubPopulation(origin, perspective = new Perspectives("GenomePerspective"), use_cache = true) {
    let subProfiles = {}
    if (use_cache) {
        const subProfiles = await getShard(origin);
        if (subProfiles) {
            return subProfiles;
        } else {
            use_cache = false;
        }
    }
    if (!use_cache) {
        const subClones = await Manager.display(origin, perspective);
        const subClones_keys = Object.keys(subClones).map((k) => { const v = k.split("_ID"); return { long: k, short: parseInt(v[1]) }; });
        for (let i = 0; i < subClones_keys.length; i++) {
            const longId = subClones_keys[i].long;
            const shortId = subClones_keys[i].short;
            const startTime = new Date();
            await Manager.profiles(shortId, new Perspectives("GenomePerspective"), false)
                .then((subProfile) => {
                    subProfiles[longId] = subProfile;
                    const keys = Object.keys(subProfile);
                    const endTime = new Date();
                    const duration = endTime.getTime() - startTime.getTime()
                },
                    (rejected) => {
                        console.error(rejected)
                        throw rejected;
                    }).catch((e) => {
                        console.error(e)
                        throw e;
                    })
                ;
        }
        ;
        saveShard(origin, subProfiles)
    }
    return subProfiles;
}


/**
 * @param {number} duration
 */
function dhms(duration) {
    const days = Math.floor(duration / (24 * 3600000));
    duration -= days * (24 * 3600000);
    const hours = Math.floor(duration / 3600000);
    duration -= hours * 3600000;
    const minutes = Math.floor(duration / 60000);
    duration -= minutes * 60000;
    const seconds = Math.floor(duration / 1000);
    duration -= seconds * 1000;
    const milliseconds = Math.floor(duration);
    return days > 0 ?
        `${days}d${('0' + hours).slice(-2)}h${('0' + minutes).slice(-2)}m`
        : (
            hours > 0 ?
                `${('0' + hours).slice(-2)}h${('0' + minutes).slice(-2)}m`
                :
                minutes > 0 ?
                    `${('0' + minutes).slice(-2)}m:${('0' + seconds).slice(-2)}s`
                    :
                    seconds > 0 ?
                        `${('0' + seconds).slice(-2)}s:${('0' + milliseconds).slice(-3)}ms`
                        :
                        `${('0' + milliseconds).slice(-3)}ms`

        );
};

/**
 * @param {any} coment
 * @param {() => any} f
 * @param {any[]} fargs
 */
export async function timeThis(coment, f, ...fargs) {
    const startTime = new Date();
    const res = await f(...fargs);
    const endTime = new Date();
    const duration = endTime.getTime() - startTime.getTime();
    console.log(`TIMETHIS::${coment}::${endTime}::${dhms(duration)}`);
    return res;
}

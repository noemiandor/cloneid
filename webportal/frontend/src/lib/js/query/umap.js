import { getShard, saveShard } from '$lib/cache/cacheproxyfs';
<<<<<<< HEAD
import { Perspectives } from '$lib/cloneid/core/utils/Perspectives';
import { Manager } from "@/lib/cloneid/cloneid/Manager";
import compare from 'just-compare';
=======
import { Manager } from "@/lib/cloneid/cloneid/Manager";
import compare from 'just-compare';
import { Perspectives } from '$lib/cloneid/core/utils/Perspectives';
>>>>>>> master

import { TMP } from '$env/static/private';
import { Buffer } from 'node:buffer';
import { mkdir, writeFile } from 'node:fs/promises';

<<<<<<< HEAD
import { count } from '../count';
import { _view } from './umapjs';
=======
import { _view } from './umapjs';
import { count } from '../count';
>>>>>>> master

const dir = TMP;

export function savePath(n, ext) {
<<<<<<< HEAD
=======
    // const ext = '.json';
>>>>>>> master
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
<<<<<<< HEAD
    try {
        const createDir = await mkdir(px['shard'], { recursive: true });
    } catch (err) {
=======
    console.log('savePath(q, v)', px);
    try {
        const createDir = await mkdir(px['shard'], { recursive: true });
        // console.log(`created ${createDir} ${px["shard"]}`);
        console.log('59::UMAP::saveFile::created ', createDir, px['shard']);
    } catch (err) {
        console.log(`61::UMAP::saveFile::created  ${createDir} ${px['shard']}`);
>>>>>>> master
        console.error(err);
        error = true;
    }
    if (error) return !error;
<<<<<<< HEAD
=======
    // const d = JSON.stringify({ k: q, v: v });
>>>>>>> master
    const data = new Uint8Array(Buffer.from(d));
    try {
        await writeFile(px['path'], data);
    } catch (err) {
        error = true;
    }
<<<<<<< HEAD
=======
    console.log(`saveFile(q, v)  ${n}`);
>>>>>>> master
    return !error;
}


/**
 * @param {any} subClones
 */
export function pie(subClones) {

    let pG = subClones;
<<<<<<< HEAD
=======
    // console.log("subProfile_keys", Object.keys(subClones['SP_0.0549219_ID69283'])[0],
    //     subClones['SP_0.0549219_ID69283']['SP_0.0157661_ID69301']['values'].length,
    //     subClones['SP_0.0549219_ID69283']['SP_0.0157661_ID69301']['loci'][0],
    //     subClones['SP_0.0549219_ID69283']['SP_0.0161058_ID69302']['loci'][0]
    // );

    // console.log("\n");
    // for (const [subClone, subProfiles] of Object.entries(subClones)) {
    //     // console.log(subClone, Object.keys(subProfiles).length);
    //     for (const [subProfile, lociAndValues] of Object.entries(subProfiles)) {
    //         // console.log(subClone, subProfile);
    //         let v = [];
    //         for (const [lociOrValue, values] of Object.entries(lociAndValues)) {
    //             // console.log(lociOrValue, values.length);
    //             v.push([`[${lociOrValue}]`, values.length, values.map((x)=>{return x.toString()}).join(",")].join("::"));
    //         }
    //         console.log([subClone, Object.keys(subProfiles).length, subProfile, ...v].join('::'));
    //         console.log();
    //     }
    // }
    // console.log("#################################################################################################################");
    // console.log("#################################################################################################################");
    // console.log("#################################################################################################################");
    // console.log("#################################################################################################################");
    // console.log("#################################################################################################################");
    // console.log("#################################################################################################################");
    // console.log("#################################################################################################################");
    // console.log("#################################################################################################################");
    // console.log("#################################################################################################################");
    // console.log("#################################################################################################################");
    // console.log("#################################################################################################################");
>>>>>>> master
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
<<<<<<< HEAD
        for (const [subProfile, lociAndValues] of Object.entries(subProfiles)) {
=======
        // console.log(subClone, Object.keys(subProfiles).length);
        for (const [subProfile, lociAndValues] of Object.entries(subProfiles)) {
            // if(cloneindex>10) throw 10;
            // console.log(subClone, subProfile);
>>>>>>> master
            for (const [lociOrValue, values] of Object.entries(lociAndValues)) {
                let index = 0;
                if (lociOrValue == 'loci') {
                    if (!compare(values, ploci)) {
<<<<<<< HEAD
                        headers['row'] = values;
                        ploci = values;
                    }
                }
                if (lociOrValue == 'values') {
=======
                        // console.log(subClone, values.length, values.map((x) => { return `${index++}@${x}` }).join("::"));
                        // console.log("\nLOCI", values.map((x) => { return `${x}`; }).join(","));
                        headers['row'] = values;
                        // console.log(typeof ploci, typeof values);
                        // console.log(ploci.length, values.length);
                        ploci = values;
                        // console.log()
                    }
                }
                if (lociOrValue == 'values') {
                    // console.log(subProfile, values.length, values.map((x) => { return `${index++}@${x}` }).join("::"));
                    // console.log(cloneindex++, subProfile,  values.map((x) => { return `${x}`; }).join(","));
>>>>>>> master
                    columns[subProfile] = values;
                    membership[subProfile] = subClone;
                    columnheader.push(subProfile);
                }
            }
<<<<<<< HEAD
=======
            // console.log()
>>>>>>> master
        }
    }
    headers['column'] = columnheader;
    matrix = { columns: columns, headers: headers };
<<<<<<< HEAD
    let clonemembershipG = [];
    for (const subProfile in subClones) {
        const subProfile_keys = Object.keys(subProfile);
        Object.keys(subClones[subProfile]).forEach((key) => {
=======
    // console.log("MATRIX",matrix);
    // console.log("Membership",membership);

    // throw 1;
    // Object.keys(subClones).forEach((subProfile) => {
    //     console.log("subProfile_keys", subProfile, Object.keys(subClones[subProfile]).length);
    //     let ploci = '';
    //     Object.keys(subClones[subProfile]).forEach((ssp) => {
    //         const loci_keys = subClones[subProfile][ssp]['loci'];
    //         const values_keys = subClones[subProfile][ssp]['values'];
    //         console.log("subProfile_keys", subProfile, ssp, values_keys.length, loci_keys.length);
    //         const loci = subClones[subProfile][ssp]['loci'][0];
    //         if (ploci != loci) {
    //             console.log(subProfile, loci, ssp);
    //             ploci = loci;
    //         }
    //     });
    // }
    // )


    // throw 1;
    // console.log("subProfile_keys", subProfile, subProfiles[subProfile], subProfile_keys);
    // /**
    //  * @type {Iterable<any> | null | undefined}
    //  */
    let clonemembershipG = [];
    // Object.keys(pG).forEach((name) => {
    //     let count = pG[name].length;
    //     clonemembershipG.push(...Array(count).fill(name));
    // });
    // clonemembershipG = unlist(clonemembershipG);

    // // clonemembershipG
    for (const subProfile in subClones) {
        const subProfile_keys = Object.keys(subProfile);
        // console.log("subProfile_keys", subProfile, subProfiles[subProfile], subProfile_keys);
        // console.log("subProfile_keys", subProfile,  subProfile_keys);
        Object.keys(subClones[subProfile]).forEach((key) => {
            // console.log("subProfile_keys::", key, subProfile);
>>>>>>> master
            clonemembershipG[key] = subProfile;
        })
    }

<<<<<<< HEAD
=======
    // console.log("clonemembershipG", clonemembershipG);

    // // clonesizesG <- sapply(pG, ncol)
    // let clonesizesG = Object.values(pG).map((subProfile) => Object.keys(subProfile).length);
    // console.log("clonesizesG", clonesizesG);

    // clonesizesG <- sapply(pG, ncol)
>>>>>>> master
    let clonesizesG = {};
    for (const [key, value] of Object.entries(pG)) {
        clonesizesG[key] = Object.keys(value).length;
    };
<<<<<<< HEAD

    let cellcountG = Object.values(clonesizesG).reduce((total, size) => total + size, 0);

    let nameG = [...new Set(Object.values(clonemembershipG))];
=======
    console.log("clonesizesG 229", clonesizesG);

    // cellcountG <- sum(clonesizesG)
    let cellcountG = Object.values(clonesizesG).reduce((total, size) => total + size, 0);
    // console.log("cellcountG", cellcountG);

    // nameG<-unique(clonemembershipG)
    let nameG = [...new Set(Object.values(clonemembershipG))];
    // console.log("nameG", nameG);



    // p1G = do.call(cbind, pG)
    // let p1G = Object.values(pG).reduce((combined, subProfile) => {
    //     return combined.concat(subProfile);
    // }, []);
    // console.log("p1G", p1G);

    // tp1G <- t(p1G)
    // let tp1G = transpose(p1G);
    // console.log("tp1G", tp1G);



    // throw 1;


    // // clonemembershipG
    // for (const subProfile in subProfiles) {
    //     const subProfile_keys = Object.keys(subProfile);
    //     // console.log("subProfile_keys", subProfile, subProfiles[subProfile], subProfile_keys);
    //     // console.log("subProfile_keys", subProfile,  subProfile_keys);
    //     Object.keys(subProfiles[subProfile]).forEach((key) => {
    //         console.log("subProfile_keys::", key, subProfile);
    //     })
    // }

    // return { d: new Date() };



    // // spsG = getSubclones(cloneID_or_sampleName = origin, whichP = "GenomePerspective")
    // // let spsG = getSubclones(origin, "GenomePerspective");

    // // pG = sapply(names(spsG), function(x) getSubProfiles(cloneID_or_sampleName = as.numeric(extractID(x)), whichP = "GenomePerspective"))
    // let pG = subProfiles;
    // // Object.keys(spsG).forEach((name) => {
    // //   let cloneID_or_sampleName = parseInt(extractID(name));
    // //   let subProfile = getSubProfiles(cloneID_or_sampleName, "GenomePerspective");
    // //   pG[name] = subProfile;
    // // });

    // // clonemembershipG = unlist(sapply(names(pG), function(x) rep(x, ncol(pG[[x]]))))
    // let clonemembershipG = [];
    // Object.keys(pG).forEach((name) => {
    //     let count = pG[name].length;
    //     clonemembershipG.push(...Array(count).fill(name));
    // });
    // console.log(clonemembershipG)
    // // clonemembershipG = unlist(clonemembershipG);

    // return subProfiles;

    // // clonesizesG <- sapply(pG, ncol)
    // let clonesizesG = Object.values(pG).map((subProfile) => subProfile[0].length);

    // // cellcountG <- sum(clonesizesG)
    // let cellcountG = clonesizesG.reduce((total, size) => total + size, 0);

    // // nameG<-unique(clonemembershipG)
    // let nameG = [...new Set(clonemembershipG)];

    // // colG=rainbow(length(nameG))
    // let colG = rainbow(nameG.length);

    // // names(colG)=nameG
    // colG = Object.fromEntries(nameG.map((name, index) => [name, colG[index]]));

    // // p1G = do.call(cbind, pG)
    // let p1G = Object.values(pG).reduce((combined, subProfile) => {
    //     return combined.concat(subProfile);
    // }, []);

    // // tp1G <- t(p1G)
    // let tp1G = transpose(p1G);


>>>>>>> master

    return clonesizesG;
}


/**
 * @param {any} subClones
 */
export function heatmap(subClones) {
<<<<<<< HEAD
    let rows = [];
    let rowheader = null;

    const subClones_entries = Object.entries(subClones);
    for (const [subClone, subProfiles] of subClones_entries) {

        if (!rowheader) {
            rowheader = { loci: subProfiles.loci };
=======
    // let pG = subClones;
    let ploci = [];
    let columns = {};
    let rows = [];
    let membership = {};
    let headers = { rows: [], columns: [] };
    // let matrix = {};
    let columnheader = [];
    let clonemembership = [];
    let rowheader = null;


    console.log("dbqgenoInfo::heatmap::UMAP.JS::293:", Object.keys(subClones).length);
    const subClones_entries = Object.entries(subClones);
    for (const [subClone, subProfiles] of subClones_entries) {
        console.log("dbqgenoInfo::UMAP2.JS::313:", count(subClone), count(subProfiles));

        if (!rowheader) {
            rowheader = { loci: subProfiles.loci };
            // rows.push(rowheader);
>>>>>>> master
        }
        let row = {};
        row['subClone'] = subClone;
        row['values'] = subProfiles.values;
        rows.push(row);
<<<<<<< HEAD
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
=======

        // const subProfiles_entries = Object.entries(subProfiles);
        // // if (Object.keys(subProfiles).length) {
        // for (const [lociAndValues, subProfile] of subProfiles_entries) {
        //     // const lociAndValues_entries = Object.entries(lociAndValues);
        //     //         for (const [lociOrValue, values] of Object.entries(lociAndValues)) {
        //     if (lociAndValues === 'loci') {
        //         if (!compare(subProfile, ploci)) {
        //             headers['row'] = subProfile;
        //             ploci = subProfile;
        //         }
        //     }
        //     if (lociAndValues == 'values') {
        //         // columns[subProfile] = values;
        //         // membership[subProfile] = subClone;
        //         // columnheader.push(subProfile);
        //         // clonemembership.push(subClone);
        //         columns[subClone] = subProfile;
        //         // membership[subProfile] = subClone;
        //         columnheader.push(subClone);
        //         // clonemembership.push(subClone);
        //     }
        //     // }
        // }
        // }
    }

    // return rows;


    // headers['column'] = columnheader;
    const rowscount = count(rows);
    const colscount = count(rowheader.loci);;
    var tmpDATA = new Array(rowscount)
    // var tmpDATA = new Array(5)
    for (let j = 0; j < rowscount; j++) {
        let row = {};
        // rows[j];
        // row['subClone'] = membership[columnheader[j]];
        row['subClone'] = rows[j].subClone;
        for (let i = 0; i < colscount; i++) {
            // for (let i = 0; i < 5; i++) {
            row[rowheader?.loci[i]] = rows[j].values[i];
        }
        // console.log(`UMAP::351::row`,row);
        // tmpDATA.push(row);
        tmpDATA[j] = row;
    }

    // console.log(`UMAP::359::row`, tmpDATA);
    // return _view("", 100, 100, tmpDATA);
    return ({coln:rowheader.loci, rown:rows.map((x)=>{return x.subClone;}), data:rows.map((x)=>{return x.values;})});
>>>>>>> master
}




/**
 * @param {any} subClones
 */
export function umap(subClones) {
<<<<<<< HEAD
=======
    console.log("UMAP::UMAP::SUBCLONES::", subClones);
    // let pG = subClones;
>>>>>>> master
    let ploci = [];
    let columns = {};
    let membership = {};
    let headers = {};
<<<<<<< HEAD
    let columnheader = [];
    let clonemembership = [];
        for (const [subClone, subProfiles] of Object.entries(subClones)) {
            if (subProfiles && Object.keys(subProfiles) && Object.keys(subProfiles).length)
                for (const [subProfile, lociAndValues] of Object.entries(subProfiles)) {
                    for (const [lociOrValue, values] of Object.entries(lociAndValues)) {
=======
    // let matrix = {};
    let columnheader = [];
    let clonemembership = [];
    if (1) {
        // console.log("dbqgenoInfo::umap::UMAP.JS::360:", Object.keys(subClones).length);
        for (const [subClone, subProfiles] of Object.entries(subClones)) {
            // console.log("dbqgenoInfo::UMAP2.JS::362:", Object.keys(subClone), Object.keys(subProfiles));
            // console.log("dbqgenoInfo::UMAP2.JS::362:", Object.keys(subClone).length, Object.keys(subProfiles).length);
            if (subProfiles && Object.keys(subProfiles) && Object.keys(subProfiles).length)
                for (const [subProfile, lociAndValues] of Object.entries(subProfiles)) {
                    console.log(Object.entries(lociAndValues));
                    for (const [lociOrValue, values] of Object.entries(lociAndValues)) {
                        // console.log("dbqgenoInfo::UMAP2.JS::316:", Object.keys(lociOrValue).length);
                        // let index = 0;
>>>>>>> master
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
<<<<<<< HEAD
    headers['column'] = columnheader;

    const colscount = columnheader.length;
=======
    }
    headers['column'] = columnheader;
    // matrix = { columns: columns, headers: headers, membership: clonemembership, uniques: [...new Set(clonemembership)] };

    const colscount = columnheader.length;
    // console.log(`UMAP::338::headers.row.length`,rowscount)
    // console.log(`UMAP::338::columnheader.length`,colscount)
    // console.log(`UMAP::338::clonemembership.length`,Object.keys(clonemembership).length);
    // console.log(`UMAP::338::columns.length`,Object.keys(columns).length);
    // console.log(`UMAP::338::headers.length`,Object.keys(headers).length);
>>>>>>> master

    var tmpDATA = new Array(colscount)
    if (headers && headers.row && headers.row.length) {
        const rowscount = headers.row.length;
<<<<<<< HEAD
        for (let j = 0; j < colscount; j++) {
            let row = {};
            row['subClone'] = membership[columnheader[j]];
            row['subProfile'] = columnheader[j];
            for (let i = 0; i < rowscount; i++) {
                row[headers.row[i]] = columns[columnheader[j]][i];
            }
=======
        // tmpDATA['columns'] = ['a']; //Object.keys(tmpDATA[0]);
        for (let j = 0; j < colscount; j++) {
            // for (let j = 0; j < 1; j++) {
            let row = {};
            row['subClone'] = membership[columnheader[j]];
            row['subProfile'] = columnheader[j];
            // console.log(`UMAP::346::columnheader[${j}]`,columnheader[j])
            for (let i = 0; i < rowscount; i++) {
                // for (let i = 0; i < 5; i++) {
                row[headers.row[i]] = columns[columnheader[j]][i];
            }
            // console.log(`UMAP::351::row`,row);
            // tmpDATA.push(row);
>>>>>>> master
            tmpDATA[j] = row;
        }
    }

<<<<<<< HEAD
    return _view("", 100, 100, tmpDATA);
}

export async function genomicProfileForSubPopulation(origin, perspective = new Perspectives("GenomePerspective"), use_cache = true) {
=======
    // let json = JSON.stringify(tmpDATA);

    // saveFile("transpose_labeled", json, '.json');

    return _view("", 100, 100, tmpDATA);


    // return clonesizesG;
}

export async function genomicProfileForSubPopulation(origin, perspective = new Perspectives("GenomePerspective"), use_cache = true) {

    // console.log("origin", origin, "perspective", perspective, "use_cache", use_cache);

>>>>>>> master
    let subProfiles = {}
    if (use_cache) {
        const subProfiles = await getShard(origin);
        if (subProfiles) {
<<<<<<< HEAD
            return subProfiles;
        } else {
=======
            // subProfiles = exist.v;
            // return exist.v;
            // subProfiles['@@date'] = new Date();
            return subProfiles;
        } else {
            // return genomicProfileForSubPopulation(origin, perspective, use_cache = false);
            // throw origin;
>>>>>>> master
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
<<<<<<< HEAD
=======
            // const subProfile =
>>>>>>> master
            await Manager.profiles(shortId, new Perspectives("GenomePerspective"), false)
                .then((subProfile) => {
                    subProfiles[longId] = subProfile;
                    const keys = Object.keys(subProfile);
<<<<<<< HEAD
                    const endTime = new Date();
                    const duration = endTime.getTime() - startTime.getTime()
=======
                    // keys.forEach((y)=>{
                    //     const sk = Object.keys(subProfile[y]);
                    //     console.log(longId,y,subProfile[y][sk[0]].length);
                    // })
                    const endTime = new Date();
                    const duration = endTime.getTime() - startTime.getTime()
                    // console.log(longId, keys.length, dhms(duration));
>>>>>>> master
                },
                    (rejected) => {
                        console.error(rejected)
                        throw rejected;
                    }).catch((e) => {
                        console.error(e)
                        throw e;
                    })
<<<<<<< HEAD
                ;
        }
        ;
        saveShard(origin, subProfiles)
=======
                .finally(() => {
                    // console.log("DONE", i);
                    // console.log("DONE", i, subProfile, dhms((new Date()).getTime() - date.getTime()));
                });
        }
        ;
        // if (use_cache){
        saveShard(origin, subProfiles)
        // }
>>>>>>> master
    }
    return subProfiles;
}


/**
 * @param {number} duration
 */
function dhms(duration) {
<<<<<<< HEAD
=======
    // export const timeDistance = (date1, date2) => {
    //     let distance = Math.abs(date1 - date2);
>>>>>>> master
    const days = Math.floor(duration / (24 * 3600000));
    duration -= days * (24 * 3600000);
    const hours = Math.floor(duration / 3600000);
    duration -= hours * 3600000;
    const minutes = Math.floor(duration / 60000);
    duration -= minutes * 60000;
    const seconds = Math.floor(duration / 1000);
    duration -= seconds * 1000;
    const milliseconds = Math.floor(duration);
<<<<<<< HEAD
=======
    // return `${days}:${hours}:${('0' + minutes).slice(-2)}:${('0' + seconds).slice(-2)}`;
    // return `${days}d${hours}h${('0' + minutes).slice(-2)}m${('0' + seconds).slice(-2)}s`;
>>>>>>> master
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
<<<<<<< HEAD
=======
    // console.log(fargs);
>>>>>>> master
    const startTime = new Date();
    const res = await f(...fargs);
    const endTime = new Date();
    const duration = endTime.getTime() - startTime.getTime();
    console.log(`TIMETHIS::${coment}::${endTime}::${dhms(duration)}`);
    return res;
}

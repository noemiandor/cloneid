import { dev } from "$app/environment";
import { getShard, saveShard } from '$lib/cache/cacheproxyfs';
import { Manager } from '@/lib/cloneid/cloneid/Manager';
import { CLONEID } from '@/lib/cloneid/database/CLONEID';
import { QueryManager } from '@/lib/cloneid/database/QueryManager';
import { fetchStmtRows } from '@/lib/mysql/fetchFromProxy';
import { spawn } from "node:child_process";
import fs from "node:fs";
import { mkdir } from 'node:fs/promises';
import { count } from '../count';
import { descendants } from './funcs';
import { genomicProfileForSubPopulation } from './geno';
import { pie } from './pie';
import { heatmap, umap } from './umap.js';
import { projectRoot } from "./util.server";


async function preferHeatmap(cellId, whichPerspective) {
    const tN = CLONEID.getTableNameForClass(whichPerspective);

    const stmtOrigin1 = `SELECT distinct origin o
    FROM Perspective t1
    JOIN Passaging t2 ON t1.origin = t2.id
    WHERE t2.passaged_from_id1="${cellId}" AND (t2.passaged_from_id1 IS NOT NULL) AND NOT EXISTS (SELECT  distinct origin FROM Perspective t1 where origin=t2.passaged_from_id1);`;
    const originEntries1 = await fetchStmtRows(stmtOrigin1);

    const stmtOrigin2 = `SELECT cloneID, size from ${tN} where origin='${cellId}' AND whichPerspective='${whichPerspective}' ORDER BY size DESC`;
    const originEntries2 = await fetchStmtRows(stmtOrigin2);
    return (originEntries1 && originEntries1.length > 0) || (originEntries2 && originEntries2.length < 20);
}


async function getHeatmapData(cellId, whichPerspective) {
    const tN = CLONEID.getTableNameForClass(whichPerspective);
    const descendantsOf = await descendants([cellId]);
    const originList = descendantsOf.map((x) => { return "'" + x.id.toString() + "'"; }).join(",");

    const rootIdStmt = `SELECT cloneID FROM ${tN} WHERE whichPerspective='${whichPerspective}' AND sampleSource='${cellId}' AND parent IS NULL`;
    const rootIdRslt = await QueryManager.executeQuery(rootIdStmt);
    rootIdRslt.next();
    const shortId = rootIdRslt.getString('cloneID');
    const sbprofiles = await Manager.profiles(shortId, whichPerspective, false);
    return sbprofiles;
}

async function uploadHeatmapData(data) {
    const cellid = data.cellid;
    const perspective = data.perspective;
    const origtype = data.origtype;
    const type = data.type;
    const coln = data.coln;
    const rown = data.rown;
    const values = data.data;

    let ls = {};
    
    let dirpath = `/heatmaps/${cellid}/`;
    const urlpath = dirpath;

    /** @type {string} */
    if (dev) {
        dirpath = `static${dirpath}`;
    } else {
        console.log("projectRoot", projectRoot);
        dirpath = projectRoot + `/client${dirpath}`;
    }
    console.log("filepath", dirpath);

    if (!fs.existsSync(dirpath + "heatmap.png")) {

        try {
            await mkdir(dirpath, { recursive: true })
                .then((x) => {
                    console.log("upload::mkdir", dirpath);
                });
        } catch (err) {
            console.error(err);
            console.log("catch::upload::mkdir", dirpath, err);
            return err;
        }

        /** @type {string} */
        let filepath;
        let valuesjson;
        let wr;

        if (values) {
            filepath = dirpath + "data.json";
            valuesjson = JSON.stringify(values);
            wr = fs.writeFileSync(filepath, valuesjson);
        }

        if (coln) {
            filepath = dirpath + "coln.json";
            valuesjson = JSON.stringify(coln);
            wr = fs.writeFileSync(filepath, valuesjson);
        }

        if (rown) {
            filepath = dirpath + "rown.json";
            valuesjson = JSON.stringify(rown);
            wr = fs.writeFileSync(filepath, valuesjson);
        }

        ls = spawn('docker', ['exec', 'qo_c1', 'Rscript', "--vanilla", "/home/docker/containerdir/20240121.R", `${cellid}`]);

        ls.stdout.on('data', (data) => {
            fs.writeFileSync(dirpath + "stdout.txt", data);
        });
        ls.stderr.on('data', (data) => {
            fs.writeFileSync(dirpath + "stderr.txt", data);
        });

        while (!fs.existsSync(dirpath + "heatmap.png")) {
            await new Promise((r) => setTimeout(r, 500));
        }

    }
    const imgdata = fs.readFileSync(dirpath + "heatmap.png");
    const imgdata64 = "data:image/png;base64," + imgdata.toString('base64');

    return {
        timestamp: new Date(),
        dirpath: dirpath,
        imgurl: urlpath + "heatmap.png",
        imgdata64: imgdata64,
        exitcode: ls && ls.exitCode ? ls.exitCode : 0,
        data: data,
        cellid: data.cellid,
        perspective: data.perspective,
        origtype: data.origtype,
        type: data.type,
        coln: data.coln,
        rown: data.rown,
        values: data.data,
    }

}




/**
 * @param {any[]} args
 */
export async function genotypeData(args) {

    const cellId = args[0];
    const whichPerspective = args[1];
    const showHeatmap = await preferHeatmap(cellId, whichPerspective);
    const infoType = (whichPerspective.toLowerCase() === "genomeperspective" && showHeatmap) ? "heatmap" : args[2];
    const query = args[3];

    let status = 200;
    let rows = [];
    let data = {};

    if (showHeatmap && infoType === 'heatmap') {
        const hmd = await getHeatmapData(cellId, whichPerspective);
        if (count(hmd)) data = heatmap(hmd);
        data['cellid'] = cellId;
        data['perspective'] = whichPerspective;
        data['origtype'] = args[2];
        data['type'] = infoType;
        return await uploadHeatmapData(data);
    }

    let d = null;
    if (!((whichPerspective.toLowerCase() === "genomeperspective" && showHeatmap))) { d = await getShard(query.toString()); }
    d = null;
    if (d) {
        data = d;
    } else {
        data = await genomicProfileForSubPopulation(cellId, whichPerspective, showHeatmap)
                .then(async (data) => {
                    switch (infoType) {
                        case 'pie':
                            data = pie(data);
                            break;
                        case 'umap':
                            data = await umap(data);
                            break;
                        case 'heatmap':
                            data = heatmap(data);
                            break;
                        default:
                            throw query.toString();
                    }
                    return data;
                })
                .catch((err) => {
                    console.log(`DBQUERYGENOTYPEINFO::GENOTYPEDATA::ERROR::`, query, err);
                    data = null;
                    throw new Error(err);
                })
            ;
    }
    if (data) {
        if (d == null) { await saveShard(query.toString(), data) };
        return data;
    }
    throw query.toString();
}
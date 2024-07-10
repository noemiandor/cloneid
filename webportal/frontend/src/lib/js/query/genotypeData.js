import { dev } from "$app/environment";
import { getShard, saveShard } from '$lib/cache/cacheproxyfs';
import { genomicProfileForSubPopulation } from './geno';
import { pie } from './pie';
import { heatmap, umap } from './umap.js';
import { count } from '../count';
import { fetchStmtRows } from '@/lib/mysql/fetchFromProxy';
import { CLONEID } from '@/lib/cloneid/database/CLONEID';
import { descendants } from './funcs';
// import { Manager } from '@/lib/cloneid/cloneid/Manager';
import { Manager } from "@/lib/cloneid/cloneid/Manager";
// import { QueryManager } from '@/lib/cloneid/database/QueryManager';
import { QueryManager } from "@/lib/cloneid/database/QueryManager";
import { projectRoot } from "./util.server";
import fs from "node:fs";
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { spawn } from "node:child_process";


async function preferHeatmap(cellId, whichPerspective) {
    const tN = CLONEID.getTableNameForClass(whichPerspective);
    console.log(`GENOTYPEDATA::preferHeatmap::11::(${cellId}, ${whichPerspective})`);
    // const selstmt = `SELECT cloneID, size from ${tN} where parent IS NULL AND hasChildren=true AND origin='${sampleName}' AND whichPerspective='${which.name()}' ORDER BY size DESC;`;

    // const stmtOrigin1 =
    //     `SELECT distinct origin
    // FROM Perspective t1
    // JOIN Passaging t2 ON t1.origin = t2.id
    // WHERE t2.passaged_from_id1="${cellId}"
    // AND (t2.passaged_from_id1 IS NOT NULL)
    // AND NOT EXISTS (SELECT DISTINCT origin FROM Perspective t1 where origin=t2.passaged_from_id1);`;
    // const originEntries1 = await fetchStmtRows(stmtOrigin1);


    const stmtOrigin1 = `SELECT DISTINCT origin o
    FROM Perspective t1
    JOIN Passaging t2 ON t1.origin = t2.id
    WHERE t2.passaged_from_id1="${cellId}"
    AND (t2.passaged_from_id1 IS NOT NULL)
    AND NOT EXISTS (SELECT DISTINCT origin FROM Perspective t1 where origin=t2.passaged_from_id1);`;
    const originEntries1 = await fetchStmtRows(stmtOrigin1);


    console.log(`GENOTYPEDATA::preferHeatmap::14::originEntries1=${originEntries1.length}::selstmt="${stmtOrigin1}"`);
    // return originEntries && originEntries.length < 20;

    const stmtOrigin2 = `SELECT cloneID, size from ${tN} where origin='${cellId}' AND whichPerspective='${whichPerspective}' ORDER BY size DESC`;
    const originEntries2 = await fetchStmtRows(stmtOrigin2);
    console.log(`GENOTYPEDATA::preferHeatmap::14::originEntries=${originEntries2.length}::selstmt="${stmtOrigin2}"`);
    return (originEntries1 && originEntries1.length > 0) || (originEntries2 && originEntries2.length < 20);
}


async function getHeatmapData(cellId, whichPerspective) {

    // out=findAllDescendandsOf("P06270_19495_mp", recursive = T)
    // mydb = cloneid::connect2DB()
    // stmt = paste0("select distinct origin from Perspective where whichPerspective='GenomePerspective' and origin IN ('",paste(unique(out$id), collapse="','"),"')")
    // rs = suppressWarnings(dbSendQuery(mydb, stmt))
    // origin=fetch(rs, n=-1)[,"origin"]
    // spP06270_19495_mp = getSubProfiles(cloneID_or_sampleName = "P06270_19495_mp", whichP = "GenomePerspective")
    // PspP06270_19495_mp=do.call(cbind, list(spP06270_19495_mp))
    // #heatmap(spP06270_19493_mp)
    // gplots::heatmap.2(t(PspP06270_19493_mp), trace = "n")

    const tN = CLONEID.getTableNameForClass(whichPerspective);
    const descendantsOf = await descendants([cellId]);
    // console.log(`GENOTYPEDATA::preferHeatmap::39::(${cellId}, ${whichPerspective})`, descendantsOf);
    const originList = descendantsOf.map((x) => { return "'" + x.id.toString() + "'"; }).join(",");

    const rootIdStmt = `SELECT cloneID FROM ${tN} WHERE whichPerspective='${whichPerspective}' AND sampleSource='${cellId}' AND parent IS NULL`;
    // const rootIdRslt = await fetchStmtRows(rootIdStmt);
    const rootIdRslt = await QueryManager.executeQuery(rootIdStmt);
    rootIdRslt.next();
    const shortId = rootIdRslt.getString('cloneID');

    const sbprofiles = await Manager.profiles(shortId, whichPerspective, false);

    // .then((subProfile) => {
    //     console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION:::78::", subProfile);
    // }
    // )
    // .catch((e) => {
    //     console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION::CATCH::89::", e);
    // })
    // ;

    // console.log("GENOJS::GENOMICPROFILEFORSUBPOPULATION:::78::", sbprofiles);
    return sbprofiles;


    // const tN = CLONEID.getTableNameForClass(whichPerspective);
    const selstmt = `SELECT DISTINCT origin FROM ${tN} WHERE whichPerspective='${whichPerspective}' AND origin IN (${originList})  ORDER BY size DESC`;
    console.log(`GENOTYPEDATA::preferHeatmap::39::(${cellId}, ${whichPerspective})`);
    // const selstmt = `SELECT cloneID, size from ${tN} where parent IS NULL AND hasChildren=true AND origin='${sampleName}' AND whichPerspective='${which.name()}' ORDER BY size DESC;`;
    // const selstmt = `SELECT cloneID, size from ${tN} where origin='${cellId}' AND whichPerspective='${whichPerspective}' ORDER BY size DESC`;
    const originEntries = await fetchStmtRows(selstmt);
    // console.log(`GENOTYPEDATA::preferHeatmap::43::originEntries=${originEntries}::selstmt="${selstmt}"`);
    return originEntries;
}



// upload: async ({ request }) => {
async function uploadHeatmapData(data) {
    // ({coln:rowheader.loci, rown:rows.map((x)=>{return x.subClone;}), data:rows.map((x)=>{return x.values;})});
    // data['cellid'] = cellId;
    // data['perspective'] = cellId;
    // data['origtype'] = args[2];
    // data['type'] = infoType;
    // data['query'] = query;

    // console.log("UPLOADHEATMAPDATA", data);
    // const formdata = await request.formData();

    // console.log("formdata", formdata);
    const cellid = data.cellid;
    const perspective = data.perspective;
    const origtype = data.origtype;
    const type = data.type;
    const coln = data.coln;
    const rown = data.rown;
    const values = data.data;

    // const userHash = formdata.get("userhash");
    // const file = formdata.get("image");
    // const index = formdata.get("index");
    // const timeStamp = formdata.get("timestamp");
    // const userHash = formdata.get("userhash");
    // console.log(file, file.name, index, timeStamp, userHash);

    // if (!(file instanceof Object) || !file.name || !index || !timeStamp || !userHash) {
    //   console.log("FAIL", fail(400, { missing: true }));
    //   return fail(400, { missing: true });
    // }
    // console.log("file", file);




    let ls = {};

    let dirpath = `/heatmaps/${cellid}/`;
    // filepath = `/cellpose/${userHash}/${timeStamp}/${file.name}`;
    const urlpath = dirpath;

    /** @type {string} */
    // let filepath;
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

        // const buffer = Buffer.from(await valuesjson.arrayBuffer());

        if (values) {
            filepath = dirpath + "data.json";
            valuesjson = JSON.stringify(values);
            wr = fs.writeFileSync(filepath, valuesjson); //, "base64");
            // console.log("filepath", filepath, wr, valuesjson);
        }

        if (coln) {
            filepath = dirpath + "coln.json";
            valuesjson = JSON.stringify(coln);
            wr = fs.writeFileSync(filepath, valuesjson); //, "base64");
            // console.log("filepath", filepath, wr, valuesjson);
        }

        if (rown) {
            filepath = dirpath + "rown.json";
            valuesjson = JSON.stringify(rown);
            wr = fs.writeFileSync(filepath, valuesjson); //, "base64");
            // console.log("filepath", filepath, wr, valuesjson);
        }

        // const sp0 = spawn('ls', ["-lahrt", "scripts", dirpath + "data.json", dirpath + "coln.json", dirpath + "rown.json", dirpath + "heatmap.png"]);
        // sp0.stdout.on('data', (data) => {
        //     // console.log(`stdout: ${data}`);
        //     fs.writeFileSync(dirpath + "log1.txt", data); //, "base64");
        // });

        // docker exec qo_c1 Rscript --vanilla /home/rstudio/containerdir/20230611_CLONEID/work/examplesForWebportal_20240110.R P06270_19495_mp
        ls = spawn('docker', ['exec', 'qo_c1', 'Rscript', "--vanilla", "/home/rstudio/containerdir/20230611_CLONEID/work/examplesForWebportal_20240121.R", `${cellid}`]);

        // const ls = spawn('Rscript', ["--vanilla", "scripts/heatmapGen.R", dirpath + "data.json", dirpath + "coln.json", dirpath + "rown.json", dirpath + "heatmap.png"]);
        // const ls = spawn('Rscript', ["--vanilla", "scripts/heatmapGen2.R", dirpath + "data.json", dirpath + "coln.json", dirpath + "rown.json", dirpath + "heatmap.png"]);
        // ls.stdout
        ls.stdout.on('data', (data) => {
            // console.log(`stdout: ${data}`);
            fs.writeFileSync(dirpath + "stdout.txt", data); //, "base64");
        });
        ls.stderr.on('data', (data) => {
            // console.log(`stderr: ${data}`);
            fs.writeFileSync(dirpath + "stderr.txt", data); //, "base64");
        });

        while (!fs.existsSync(dirpath + "heatmap.png")) {
            await new Promise((r) => setTimeout(r, 500));
        }

    }
    const imgdata = fs.readFileSync(dirpath + "heatmap.png");
    const imgdata64 = "data:image/png;base64," + imgdata.toString('base64');

    // return ls.exitCode;
    // const cellid = data.cellid;
    // const perspective = data.perspective;
    // const origtype = data.origtype;
    // const type = data.type;
    // const coln = data.coln;
    // const rown = data.rown;
    // const values = data.data;
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

    console.log("genotypeData(args)", args);

    const cellId = args[0];
    const whichPerspective = args[1];
    console.log(`GENOTYPEDATA::(${args.join('::')})`);
    // const showHeatmap = await preferHeatmap(cellId, whichPerspective);
    // // const infoType = showHeatmap ? (args[2] === "umap" ? "heatmap" : "umap") : args[2];
    // const infoType = (whichPerspective.toLowerCase() === "genomeperspective" && showHeatmap) ? "heatmap" : args[2];
    const showHeatmap = false;
    const infoType = args[2];
    const query = args[3];

    let status = 200;
    let rows = [];
    let data = {};

    // if (showHeatmap && infoType === 'heatmap') {
    //     const hmd = await getHeatmapData(cellId, whichPerspective);
    //     // data = umap(hmd);
    //     if (count(hmd)) data = heatmap(hmd);
    //     data['cellid'] = cellId;
    //     data['perspective'] = whichPerspective;
    //     data['origtype'] = args[2];
    //     data['type'] = infoType;
    //     // data['query'] = query;
    //     // await uploadHeatmapData(data);
    //     // return data;
    //     return await uploadHeatmapData(data);
    // }

    // const d = useCache ? await getShard(query.toString()) : null; // full query
    let d = null;
    // if (!((whichPerspective.toLowerCase() === "genomeperspective" && showHeatmap))) {
    //     d = await getShard(query.toString());
    // }
    // d = null;
    // d = await getShard(query.toString());
    console.log("DBQUERYGENOTYPEINFO::GENOTYPEDATA::30::GET::", query.toString(), d);
    if (d) {
        // if (d && count(d)>0) {
        data = d;
        console.log("DBQUERYGENOTYPEINFO::GENOTYPEDATA::33::getShard::", query.toString(), d.length);
    } else {
        console.log("DBQUERYGENOTYPEINFO::GENOTYPEDATA::36:", infoType, cellId, whichPerspective);
        data = await genomicProfileForSubPopulation(cellId, whichPerspective, showHeatmap)
                .then(async (data) => {
                    console.log("DBQUERYGENOTYPEINFO::GENOTYPEDATA::31:", infoType, cellId, whichPerspective, Object.keys(data), count(data));
                    if (count(data) > 0) {
                        switch (infoType) {
                            case 'pie':
                                // console.log("DBQUERYGENOTYPEINFO::GENOTYPEDATA::34:", infoType, cellId, whichPerspective, Object.keys(data));
                                data = pie(data);
                                // console.log("DBQUERYGENOTYPEINFO::GENOTYPEDATA::36:", infoType, cellId, whichPerspective, data.length);
                                break;
                            case 'umap':
                                // console.log("DBQUERYGENOTYPEINFO::GENOTYPEDATA::37:", infoType, cellId, whichPerspective, count(data));
                                data = await umap(data);
                                // console.log("DBQUERYGENOTYPEINFO::GENOTYPEDATA::40:", infoType, cellId, whichPerspective, count(data));
                                break;
                            case 'heatmap':
                                // console.log("DBQUERYGENOTYPEINFO::GENOTYPEDATA::HEATMAP::63", infoType, cellId, whichPerspective, data);
                                data = heatmap(data);
                                // console.log("DBQUERYGENOTYPEINFO::GENOTYPEDATA::HEATMAP::65", infoType, cellId, whichPerspective, data);
                                break;
                            default:
                                console.log("DBQUERYGENOTYPEINFO::GENOTYPEDATA::52:", infoType, cellId, whichPerspective, data);
                                throw query.toString();
                        }
                        return data;
                    } else {
                        return null;
                    }
                    if (data) { return data; } else { return null; }
                })
                .catch((err) => {
                    console.log(`DBQUERYGENOTYPEINFO::GENOTYPEDATA::ERROR::`, query, err);
                    data = null;
                    throw new Error(err);
                })
            // .finally(() => {
            //     if (false) console.log( "idString", cellId, "status", status, "data", data);
            // })
            ;
        console.log(`DBQUERYGENOTYPEINFO::GENOTYPEDATA::58::`);
    }
    if (count(data) > 0) {
        console.log(`DBQUERYGENOTYPEINFO::GENOTYPEDATA::329::`);
        if (d == null) { await saveShard(query.toString(), data) };
        return data;
    }
    console.log(`DBQUERYGENOTYPEINFO::GENOTYPEDATA::67::`);
    // throw query.toString();
}
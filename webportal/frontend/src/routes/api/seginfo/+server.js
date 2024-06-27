/** @type {import('./$types').RequestHandler} */

import { CELLPOS_DIR, SQLPSWD, SQLSCHM, SQLUSER } from '$env/static/private';
import { serverCreateJbPayload } from '@/lib/jobs/funcs.server';
import { normalisePathFromComponents } from '@/lib/jobs/path';
import { sqlpswd, sqluser } from '@/lib/mysql/sqlinfo';
import { json } from '@sveltejs/kit';
import fs from "node:fs";


async function import2cloneid(d) {
    if (
        !(
            d.timestamp &&
            d.userhash &&
            d.imageid &&
            d.from &&
            d.results.media &&
            d.results.flask &&
            d.results.cellCount &&
            d.event &&
            d.flaskitems &&
            d.mediaitems &&
            d.username &&
            true
        )
    ) {
        throw d;
    }
    process.env.SQLUSER = await sqluser(d.username);
    process.env.SQLPSWD = await sqlpswd(d.username);
    
    let imageset = d.s;

    const txid = (new Date()).getTime();
    const payload = [
        'Rscript', '--vanilla',
        "/opt/lake/data/cloneid/module02/data/scripts/R/I2C/T2.R",
        d.event, d.imageid, d.from, d.cellcount, d.timestamp, d.flask, d.media,
        "sql2", 3306, process.env.SQLUSER, process.env.SQLPSWD, SQLSCHM,
        CELLPOS_DIR, 'imagesets', imageset, txid, 'i2c'
    ];
    console.log("PAYLOAD", payload.join("::"));
    const p = { spawn: payload };
    const jid = await serverCreateJbPayload('m2.cellpose', 'waiting', txid, p);
    return ({ i: jid.i });
}








/**
 * @param {string} s
 */
async function serverLoadSeginfo(s) {

    const srcimgset = normalisePathFromComponents([CELLPOS_DIR, 'imagesets', s]);
    const srcoutput = normalisePathFromComponents([srcimgset, 'output']);
    const srcimages = normalisePathFromComponents([srcoutput, 'Images']);
    const srcrsults = normalisePathFromComponents([srcimgset, 'results']);

    const processedd = normalisePathFromComponents([srcrsults, 'seginfodata.json']);
    const processedi = normalisePathFromComponents([srcrsults, 'seginfoimgs.json']);
    const processedl = normalisePathFromComponents([srcrsults, 'seginfodate.log']);


    if (
        fs.existsSync(processedl) &&
        fs.existsSync(processedi) &&
        fs.existsSync(processedd) &&
        true
    ) {
        const date = fs.readFileSync(processedl).toString();
        const data = fs.readFileSync(processedd).toString();
        const imgs = fs.readFileSync(processedi).toString();

        return ({
            date: date,
            data: data,
            imgs: imgs,
        });
    } else {
        return ({
            date: {},
            data: "",
            imgs: {},
        });
    }
}


/**
 * @param {string} s
 */
async function serverLoadImgInfo(s) {

    const srcimgset = normalisePathFromComponents([CELLPOS_DIR, 'imagesets', s]);
    const srcoutput = normalisePathFromComponents([srcimgset, 'output']);
    const srcimages = normalisePathFromComponents([srcoutput, 'Images']);
    const srcrsults = normalisePathFromComponents([srcimgset, 'results']);

    const processedi = normalisePathFromComponents([srcrsults, 'seginfoimgs.json']);

    if (
        fs.existsSync(processedi) &&
        true
    ) {
        const imgs = fs.readFileSync(processedi).toString();

        return ({
            imgs: imgs,
        });
    } else {
        return ({
            imgs: {},
        });
    }
}

async function processReq(method, d) {
    process.env.SQLUSER = await sqluser(d.username);
    process.env.SQLPSWD = await sqlpswd(d.username);
    let data = {};
    let status = 200;
    switch (d.x) {
        case 'r': //retrieve
        case 'retrieve': //retrieve
            data['r'] = await serverLoadSeginfo(d.s);
            break;
        case 'imgs': //retrieve
            data['r'] = await serverLoadImgInfo(d.s);
            break;
        case 'i':
            data = await import2cloneid(d);
            break;
    }
    return json(
        { data: data, t: (new Date()).getTime() },
        {
            status: status,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    );
}

export async function POST({ request }) {
    const d = await request.json();
    return processReq('post', d)
}
export async function GET(request) {
    let d = {};
    for (const [k, v] of request.url.searchParams) { d[k] = v; }
    return processReq('get', d)
}

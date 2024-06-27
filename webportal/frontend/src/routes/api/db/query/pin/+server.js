/** @type {import('./$types').RequestHandler} */

import { json } from '@sveltejs/kit';

/**
 * @param {{ url: { searchParams: any; }; }} req
 */
async function processReq(req) {
    let data = [];
    let status = 200;
    const params = req.url.searchParams;
    let d = {};
    for (const [k, v] of params) { d[k] = v; data.push({ k: v }); }
    
    return json(
        { data: {result:((d.pin).toLowerCase() === "m2clid")}, date: new Date() },
        {
            status: status,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    );
}

export async function POST(req) { return processReq(req) }
export async function GET(req) { return processReq(req) }

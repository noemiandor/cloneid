/** @type {import('./$types').RequestHandler} */

import { json } from '@sveltejs/kit';
import { afianswer, createJbPayload, findAndExtractJbPayload, findAndExtractMultipleJbPayload, serverCreateJbPayload } from '@/lib/jobs/funcs.server';



async function processReq(req) {
    let data = [];
    let status = 200;
    const params = req.url.searchParams;
    let d = {};
    for (const [k, v] of params) { d[k] = v; data.push({ k: v }); }
    if (!(d.i && d.action)) {
        console.log('processReq X', d);
        throw d;
    }
    let r;
    switch (d.action) {
        case 'a': //add
        case 'add': //add
        case 'publish': //add
            r = await createJbPayload(d.a, d.q, d.i, d.p);
            break;
        case 'r': //retrieve
        case 'retrieve': //retrieve
            if ('operation' in d && d.operation === 'multiple') {
                r = await findAndExtractMultipleJbPayload(d.a, d.q, d.i);
            } else {
                r = await findAndExtractJbPayload(d.a, d.q, d.i);
            }
            break;
        case 'k': //kill
            break;
        case 'h': // hold
            break;
        case 'p': // postpone
            break;
        case 'w': //wait
            break;
        case 'afianswer': //retrieve
            await afianswer(d);
            r = [];
            break;
    }
    return json(
        { data: r, date: new Date(), jid: (new Date()).getTime() },
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

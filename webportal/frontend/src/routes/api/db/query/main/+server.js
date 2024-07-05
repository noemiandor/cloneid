/** @type {import('./$types').RequestHandler} */

import { base } from '@/lib/js/query/mainPageData';
import { loadCachedFromArgs } from '@/lib/cache/cacheproxyfs';
import { jsonResponse } from '@/lib/js/response/jsonrows';

const fromCache = true;

/**
 * @param {{ url: { searchParams: any; }; }} req
 */
export async function GET(req) {
    const query = req.url.searchParams;
    const type = query.get('t');
    const val = query.get('v');

    let status = 200;
    let rows = [];

    if (!(type && val)) { throw query; }

    const cached = await loadCachedFromArgs(["query", "base", type, val]);

    if (fromCache && cached) {
        rows = cached;
    } else {
        if (typeof base == 'function') {
            const args = [type, val];
            rows = await base(args)
                .then((values) => {
                    return values;
                })
                .catch((e) => {
                    console.log("TREE::QUERY::SERVERJS::GET::ERROR::", query, e);
                    status = 500;
                });
        }else{
            throw "VALUES NOT IN CACHE";
        }

    }
    return jsonResponse(query, rows, status);
}
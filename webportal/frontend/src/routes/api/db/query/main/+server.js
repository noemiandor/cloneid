/** @type {import('./$types').RequestHandler} */

import { base } from '@/lib/js/query/mainPageData';
import { loadCachedFromArgs } from '@/lib/cache/cacheproxyfs';
import { jsonResponse } from '@/lib/js/response/jsonrows';

const fromCache = false;

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
            console.log(["query", "base", type, val, cached]);

    if (fromCache && cached) {
        rows = cached;
    } else {
        if (typeof base == 'function') {
            // NON CACHED
            // PLACEHOLDER MODULE 3
            console.log("PLACEHOLDER MODULE 3");
        }
    }
    return jsonResponse(query, rows, status);
}
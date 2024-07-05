/** @type {import('./$types').RequestHandler} */

import { hasGenotypicInfo } from '@/lib/js/query/hasGenotypicInfoData';
import { loadCachedFromArgs } from '@/lib/cache/cacheproxyfs';
import { jsonResponse } from '@/lib/js/response/jsonrows';

const fromCache = true;

/**
 * @param {{ url: { searchParams: any; }; }} req
 */
export async function GET(req) {
    const query = req.url.searchParams;
    const cellId = query.get('id');

    let status = 200;
    let rows = [];

    if (!cellId) { throw query; }

    const args = ["dbqueryharvestwithgenotypicinfo", "hasGenotypicInfo", cellId];
    const cached = await loadCachedFromArgs(args);

    if (fromCache && cached) {
        rows = cached;
    } else {
        if (typeof hasGenotypicInfo == 'function') {
            // NON CACHED
            // PLACEHOLDER MODULE 3
            console.log("PLACEHOLDER MODULE 3");
        }
    }
    return jsonResponse(query, rows, status);
}
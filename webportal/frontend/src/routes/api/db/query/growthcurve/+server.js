/** @type {import('./$types').RequestHandler} */
import { descendants } from '$lib/js/query/funcs';
import { cachedKey, loadCachedFromArgs, storeCached } from '@/lib/cache/cacheproxyfs';
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

    const args = ["dbquerygrowthcurve", "descendants", cellId];
    const cached = await loadCachedFromArgs(args);

    if (fromCache && cached) {
        rows = cached;
    } else {
        // NON CACHED
        // PLACEHOLDER MODULE 3
        if (typeof descendants == 'function') {
            const args = [cellId];
            rows = await descendants(args)
                .then((values) => {
                    return values;
                })
                .catch((e) => {
                    console.log("GROWTHCURVE::SERVERJS::DESCENDANTS:::ERROR::", query);
                    console.log();
                });
            // TO REMOVE
            if (rows) {
                storeCached(cachedKey(args), rows);
            }
        } else {
            throw "VALUES NOT IN CACHE";
        }
    }
    return jsonResponse(query, rows, status);
}
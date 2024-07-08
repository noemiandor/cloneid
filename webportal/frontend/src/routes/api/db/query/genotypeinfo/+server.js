/** @type {import('./$types').RequestHandler} */
import { genotypeData } from '$lib/js/query/genotypeData';
import { cachedKey, loadCachedFromKey, storeCached } from '@/lib/cache/cacheproxyfs';
import { jsonResponse } from '@/lib/js/response/jsonrows';

const fromCache = !true;

/**
 * @param {{ url: { searchParams: any; }; }} req
 */
export async function GET(req) {
    const query = req.url.searchParams;
    const cellId = query.get('id');
    const whichPerspective = query.get('perspective');
    const infoType = query.get('info');

    let status = 200;
    let rows = [];

    if (!(cellId && whichPerspective && infoType)) { throw query };

    const args = ["genotypeData", "dbquerygenotypeinfo", cellId, whichPerspective, infoType];
    const cached = await loadCachedFromKey(query.toString());
    if (fromCache && cached) {
        rows = cached;
    } else {
        // NON CACHED
        // PLACEHOLDER MODULE 3
        if (typeof genotypeData == 'function') {
            const args = [cellId, whichPerspective, infoType, query];
            rows = await genotypeData(args)
                .then((values) => {
                    return values;
                })
                .catch((e) => {
                    console.log("GENOTYPEINFO::SERVERJS::GET::ERROR::", query, e);
                    console.log();
                    status = 500;
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
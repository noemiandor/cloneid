import { fetchStmt } from '@/lib/mysql/fetchFromProxy';

/**
 * @param {String} ids
 */
export async function findAllDescendandsOf(ids) {

    /**
     * @param {string} stmt
     */
    async function executeSql(stmt) {
        const data = await fetchStmt(stmt);
        const rows = data.rows.filter(id => id !== "").map((/** @type {{ id: string; }} */ row) => row.id);
        return rows;
    }

    /**
     * @param {string} id
     */
    async function traceDescendands(id) {
        const stmt = `select id, passaged_from_id1 from Passaging where passaged_from_id1='${id}';`;
        const kids = await executeSql(stmt);
       
            let out = kids;
            for (const id of kids) {
                const siblings = await traceDescendands(id);
                out = [...out, ...siblings];
            }
            return out;
    }

    const idsArray = ids.split(',').map(id => id.trim());
    const stmt = `select id,date from Passaging where id IN ( ${idsArray.map(id => `'${id}'`).join(', ')} ) order by date DESC;`;
    const parents = await executeSql(stmt);


        /**
         * @type {string[]}
         */
        let alllineages = [];
        let out = {};

        for (let id of parents) {
            const descendants = await traceDescendands(id);
            let d = [id, ...descendants];
            d = d.filter(val => !(alllineages.includes(val))); // exclude descendants with more recent parent (i.e. seedings)
            alllineages = [...alllineages, ...d];
            let queryParam = `('${d.join("', '")}')`;
            out[id] = `select *, '${id}' as Ancestor from Passaging where id IN ${queryParam}`;
        }

        let stmt = out[Object.keys(out)[0]];
        let keys = Object.keys(out).filter(val => !(Object.keys(out).includes(Object.keys(out)[0])));
        for (let id of keys) {
            stmt += " UNION (" + out[id] + ")";
        }
        const result = await fetchStmt(stmt);
        return result;
}
// import { fetchStmt } from '$lib/mysql/fetchproxy';
import { fetchStmt } from '@/lib/mysql/fetchFromProxy';

/**
 * @param {string} cellLine
 */
export async function cellLineOrLineageId(cellLine) {
    /**
     * @param {string} stmt
     */
    async function executeSql(stmt) {
        const data = await fetchStmt(stmt);
        const rows = data.rows;
        return data;
    }

    /**
     * @param {string} _id
     */
    function buildSqlStmt(_id) {
        const stmt = `SELECT id,passage,cellLine,event,passaged_from_id1 FROM Passaging WHERE cellLine='${_id}' ORDER BY passage ASC;`
        return stmt;
    }


    const stmt = buildSqlStmt(cellLine);
    const result = await executeSql(stmt);

    return result;
}

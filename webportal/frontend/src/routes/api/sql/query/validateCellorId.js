// import { count } from '@/lib/js/count';
import { fetchStmt, fetchStmtRows } from '@/lib/mysql/fetchFromProxy';

/**
 * @param {string} val
 */
export async function validateCellLine(val) {
    return await fetchStmtRows(`select id, cellLine, count(*) as count from Passaging where id IN ('${val}') and id=cellLine;`);
}

/**
 * @param {string} val
 */
export async function validateCellId(val) {
    return await fetchStmtRows(`select id, cellLine, count(*) as count from Passaging where id IN ('${val}') and id!=cellLine;`);
}

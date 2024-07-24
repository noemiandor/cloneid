import { sqlQuery } from '$lib/cloneid/database/sqlQuery';
import { QueryResult } from './QueryResult';

export class QueryManager {

    /**
         * @param {string} stmt
         */
    static async executeSql(stmt) {
        return sqlQuery.fetchStmt(stmt);
    }

    /**
     * @param {string} stmt
     */
    static executeQuery = async function (stmt) {
        /**
         * @type {QueryResult|null}
         */
        let result = null;
        let rejected = false;
        let exception = false;
        do {
            await sqlQuery.fetchStmt(stmt)
                .then((res) => {
                    const rs = new QueryResult(res);
                    result = rs;
                },
                    (reject) => {
                        rejected = true;
                        throw reject;
                    })
                .catch((error) => {
                    exception = true;
                    throw error;
                })
                .finally(() => {
                    return result;
                });
        } while (rejected || exception);
        if (result == null) {
            console.log("QuertManager::executeQuery::return", result);
        }
        return result;
    }
}
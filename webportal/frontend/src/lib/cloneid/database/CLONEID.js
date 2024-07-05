import { count } from '@/lib/js/count';
import { Helper } from '../core/utils/Helper';
import { Perspectives } from '../core/utils/Perspectives';
import { Clone_getInstance } from '../core/utils/Statics';
import { QueryManager } from './QueryManager';
import { SerializeProfile_MySQL } from './SerializeProfile_MySQL';

export class CLONEID {
    constructor() {
        this.con = null;
        this.stmt = QueryManager;
    }

    connect() {
        return true;
    }

    /**
     * @param {string} stmt
     */
    async executeSql(stmt) {
        return await QueryManager.executeQuery(stmt);
    }

    close() {
    }

    executeUpdate(addstmt) {
        this.stmt.executeUpdate(addstmt);
    }

    getConnection() {
        return this.con;
    }
    /**
     * @return {typeof QueryManager}
     */
    getStatement() {
        return QueryManager;
    }

    /**
     * @param {string} cloneClass
     */
    static getTableNameForClass(cloneClass) {
        let tableName = "Identity";
        if (!cloneClass.includes(tableName)) {
            tableName = "Perspective";
        }
        if (cloneClass.toLowerCase().includes("morphologyperspective")) {
            tableName = "MorphologyPerspective";
        }
        return tableName;
    }

    /**
     * @param {number} cloneID
     * @param {Perspectives} whichP
     */
    async getClone(cloneID, whichP) {
        const which = (typeof whichP == 'string') ? whichP : whichP.name();
        if (!cloneID || Number.isNaN(cloneID)) return;

        let attr = "size,origin,whichPerspective,parent,coordinates";
        if (which === Perspectives.Identity) {
            attr += "," + Object.values(Perspectives).filter(p => p !== Perspectives.Identity).join(",");
        }
        const serp = new SerializeProfile_MySQL(cloneID, which);
        const p = await serp.readProfileFromDB(this.con);
        const table = CLONEID.getTableNameForClass(which);
        const selstmt = `SELECT ${attr} from ${CLONEID.getTableNameForClass(which)} where cloneID=${cloneID};`;
        return await this.stmt.executeQuery(selstmt)
            .then(async (rs) => {
                rs.next();
                const parentID = rs.getInt("parent");
                const coordinates = rs.getString("coordinates");
                const clone = Clone_getInstance(rs.getFloat(1), rs.getString(2), new Perspectives(which), p.getLoci());
                if (coordinates !== null) {
                    const coord = Helper.string2double(coordinates.split(","));
                    clone.setCoordinates(coord[0], coord[1]);
                }
                clone.setProfile(p);
                clone.setID(cloneID);
                const pmap = new Map();
                if (which === Perspectives.Identity.normalize()) {
                    for (const persp of Object.values(Perspectives)) {
                        if (persp !== Perspectives.Identity) {
                            const pIDs = rs.getString(persp.name());
                            if (pIDs !== null) {
                                for (const pID of pIDs.split(",")) {
                                    pmap.set(parseInt(pID), persp);
                                }
                            }
                        }
                    }
                }
                const childrenForParents = await this.getChildrenForParent(cloneID, new Perspectives(which));
                clone.setChildrenIDs(childrenForParents);
                if (parentID) {
                    const parent = await this.getClone(parentID, new Perspectives(which));
                    clone.setParent(parent);
                }
                for (const [key, value] of pmap.entries()) {
                    const pers = await this.getClone(key, value);
                    console.log("CLONEID::148::", key, value, pers);
                    clone.addPerspective(pers);
                }
                return clone;
            });
    }

    /**
     * @param {number} cloneID
     * @param {Perspectives} which
     */
    async getChildrenForParent(cloneID, whichP) {
        const which = (typeof whichP == 'string') ? whichP : whichP.name();
        const selstmt0 = `SELECT COUNT(*) as count from ${CLONEID.getTableNameForClass(which)} WHERE parent=${cloneID};`;
        return await QueryManager.executeQuery(selstmt0)
            .then(async (rs) => {
                if (!rs) throw rs;
                rs.next();
                const count = rs.getInt(1);
                if (count > 0) {
                    /**
                     * @type {any[] | PromiseLike<any[]>}
                     */
                    const childrenIDs = [];
                    const selstmt2 = `SELECT cloneID FROM ${CLONEID.getTableNameForClass(which)} WHERE parent=${cloneID};`;
                    return await QueryManager.executeQuery(selstmt2)
                        .then((rs2) => {
                            for (let i = 0; i < count; i++) {
                                rs2.next();
                                childrenIDs[i] = rs2.getInt("cloneID");
                            }
                            return childrenIDs;
                        })
                        .catch((e) => {
                            throw e;
                        });
                } else {
                    return [];
                }
            });

    }

    /**
     * @param {{ constructor: { name: any; }; getID: () => any; }} child
     * @param {any} fieldname
     * @param {any} fieldvalue
     */
    update(child, fieldname, fieldvalue) {
        throw "CLONID:update:";
    }

}

import { CLONEID } from '../database/CLONEID';
import { QueryManager } from '../database/QueryManager';

export class Manager {

    static async gatherForDisplay(selstmt, cloneID_or_sampleName, which) {
        const cloneidInstance = new CLONEID();
        const rs = await cloneidInstance.getStatement().executeQuery(selstmt);
        const cloneSizes = {};
        rs.next();
        const parentID = rs.getString("cloneID");
        const parent = await cloneidInstance.getClone(parentID, which);
        const kids = await cloneidInstance.getChildrenForParent(parent.getID(), which);
        if (kids != null) {
            for (const kid of kids) {
                const clone = await cloneidInstance.getClone(kid, which);
                cloneSizes[clone.toString()] = clone;
            }
        } else {
            cloneSizes[cloneID_or_sampleName] = parent;
        }
        return cloneSizes;
    }

    static async profiles(cell, whichP, includeRoot) {

        const which = (typeof whichP === 'string'?whichP:whichP.name())
        const table = CLONEID.getTableNameForClass(which);
        const cellType = (typeof cell == 'string');

        const isOrigin = Number.isNaN(parseInt(cell)) ? true : false;

        
        const sqlStmt = isOrigin
        ?
        `SELECT size, cloneID FROM ${table} WHERE hasChildren=true AND origin='${cell}'  AND whichPerspective='${which}' ORDER BY size DESC;`
        :
        `SELECT size, cloneID FROM ${table} WHERE cloneId='${cell}' AND whichPerspective='${which}' ORDER BY size DESC;`

        const gatheredProfiles = await Manager.gatherProfiles(sqlStmt, which, includeRoot);
        return gatheredProfiles;
    }

    static async profile(cloneID, which) {
        const profiles = {};
        const cloneidInstance = new CLONEID();
        await cloneidInstance.connect();

        const clone = await cloneidInstance.getClone(cloneID, which);
        profiles[clone.toString()] = clone.getProfile();
        await cloneidInstance.close();

        return profiles;
    }
    static async gatherProfiles(selstmt, which, includeRoot) {
        const cloneid = new CLONEID();
        const rs = await QueryManager.executeQuery(selstmt);
        rs.next();

        var profiles = {};
        const root = await cloneid.getClone(rs.getInt("cloneID"), which);
        if (root) {
            const kids = await cloneid.getChildrenForParent(root.getID(), which);
            for (const kid of kids) {
                const clone = await cloneid.getClone(kid, which);
                profiles[clone.toString()] = await clone.getProfile();
            }
            if (includeRoot) {
                profiles[root.toString()] = await root.getProfile();
            }
        }
        return profiles;
    }

    static async displayId(cloneID, which) {
        const tN = CLONEID.getTableNameForClass(which.name());
        const selstmt = `SELECT parent, cloneID, size from ${tN} where cloneID=${cloneID} AND whichPerspective='${which.name()}' ORDER BY size DESC;`;
        const cloneSizes = await Manager.gatherForDisplay(selstmt, cloneID + "", which);
        return cloneSizes;
    }

    static async display(sampleName, which) {
        const tN = CLONEID.getTableNameForClass(which.name());
        const selstmt = `SELECT cloneID, size from ${tN} where parent IS NULL AND hasChildren=true AND origin='${sampleName}' AND whichPerspective='${which.name()}' ORDER BY size DESC;`;
        const cloneSizes = await Manager.gatherForDisplay(selstmt, sampleName, which);
        return cloneSizes;
    }

    static async compare(cloneID1, which1, cloneID2, which2) {
        const db = new CLONEID();
        await db.connect();

        const c1 = await db.getClone(cloneID1, which1);
        const c2 = await db.getClone(cloneID2, which2);

        const out = [Helper.toDouble(c1.getProfile().getValues()), Helper.toDouble(c2.getProfile().getValues())];
        return out;
    }
    static createSchema(yamlReader, forceCreateSchema) {
        const STDERR_PREFIX = "JAVADB: ";
        const NO_CHANGES_MADE_TO_DB = "No changes made to database: " + yamlReader.getConfig().getMysqlConnection().database;

        const dbService = new DatabaseService(
            yamlReader.getConfig().getMysqlConnection().host,
            yamlReader.getConfig().getMysqlConnection().port,
            yamlReader.getConfig().getMysqlConnection().user,
            yamlReader.getConfig().getMysqlConnection().password,
            yamlReader.getConfig().getMysqlConnection().database,
            yamlReader.getConfig().getMysqlConnection().schemaScript,
            yamlReader.getConfig().getDbTables(),
            forceCreateSchema
        );

        try {
            dbService.createSchema();
        } catch (e) {
            console.error(STDERR_PREFIX + e.message);
            console.error(STDERR_PREFIX + "Unable to create CLONEID Schema");
            console.error(STDERR_PREFIX + NO_CHANGES_MADE_TO_DB);
            console.error(STDERR_PREFIX + "Please check username, password and/or database permissions");
        }
    }
}

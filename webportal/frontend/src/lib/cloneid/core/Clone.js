import { CLONEID } from "../database/CLONEID";
import { CloneColumnPrefix } from "../useri/CloneColumnPrefix";
import { Perspectives } from "./utils/Perspectives";

export class Clone {
    constructor(size, sampleName) {
        this.PRECISION = 0.00000005;
        this.size = size;
        this.parent = null;
        this.children = [];
        this.sampleSource = null;
        this.cloneID = null;
        this.profile = null;
        this.childrenIDs = [];
        this.coordinates = [];
        this.redundant = false;
        this.state = '';
        this.alias = '';

        this.setCellLineOrPatientFor(sampleName);
        this.children = [];
    }

    addChild(clone) {
        this.children.push(clone);
    }
    init(outFile, whichPerspective, parentCloneID) {
        const sampleName = outFile.getName().split("\\.")[0];
        try {
            this.size = parseFloat(parentCloneID.split("_")[1]);
        } catch (e) {
            this.size = 1;
            e.printStackTrace();
        }
        const lines = Files.readAllLines(Paths.get(outFile.getAbsolutePath()), Charset.defaultCharset());
        while (lines[0].startsWith("#")) {
            lines.shift();
        }
        const header = lines[0].split(Helper.TAB);
        const loci = Helper.apply(Helper.sapply(lines.slice(1, lines.length), "split", Helper.TAB), "get", Helper.firstIndexOf("LOCUS", header));

        const cloneI = [];
        const metaI = Helper.firstIndexOf(parentCloneID, header);
        if (metaI < 0) {
            loadFromDB();
        } else {
            this.profile = Clone.getInstance(size, sampleName, whichPerspective, loci).profile;
        }
        for (let sI = 0; sI < header.length; sI++) {
            if (sI === metaI) {
                continue;
            }
            if (header[sI].matches(CloneColumnPrefix.getValue(whichPerspective) + "\\d*_\\d+.*")) {
                cloneI.push(sI);
                const hfeatures = header[sI].split("_");
                const size = parseFloat(hfeatures[1]);

                const p_ = Clone.getInstance(size, sampleName, whichPerspective, loci);
                if (hfeatures.length > 2) {
                    p_.state = hfeatures[2];
                }
                if (hfeatures.length > 3) {
                    p_.alias = hfeatures[3];
                }
                this.addChild(p_);
            }
        }

        for (let i = 1; i < lines.length; i++) {
            const cont = lines[i].split(Helper.TAB);
            for (let j = 0; j < cloneI.length; j++) {
                const cI = cloneI[j];
                this.children[j].getProfile().modify(i - 1, Helper.parseDouble(cont[cI]));
            }
            if (metaI >= 0) {
                this.profile.modify(i - 1, Helper.parseDouble(cont[metaI]));
            }
        }
    }

    /**
     * @param {string} stmt
     */
    async executeSql(stmt) {
        const data = await fetchStmt(stmt);
        return data;
    }

    loadFromDB() {
        const db = new CLONEID();
        db.connect();

        const selstmt = `SELECT cloneID,coordinates from ${CLONEID.getTableNameForClass(this.constructor.name)} where abs(size-${size})<${PRECISION} AND whichPerspective='${this.constructor.name}' AND sampleSource='${sampleSource}';`;
        const rs = db.getStatement().executeQuery(selstmt);
        rs.next();
        this.cloneID = rs.getInt("cloneID");
        this.coordinates = Helper.string2double(rs.getString("coordinates").split(","));
        const serp = new SerializeProfile_MySQL(cloneID, this.constructor.name);
        this.profile = serp.readProfileFromDB(db.getConnection());
        db.close();
    }

    getProfile() {
        return this.profile;
    }

    async setCellLineOrPatientFor(origin2) {
        if (!this.constructor.name === "Identity") {
            this.origin = origin2;
        }
        const db = new CLONEID();
        const selstmt = `SELECT cellLine from Passaging where id = '${origin2}';`;
    
        const rs = await db.executeSql(selstmt);
        if (rs) {
            rs.next();
            const rows = rs.rows;
            if (rows) {
                const row = rows[0];
                this.sampleSource = rs.getString("cellLine");
            } else {
                throw rs;
            }
        } else {
            throw rs;
        }

    }

    getDBformattedAttributesAsMap() {
        const map = new Map();
        map.set("size", `${size}`);
        if (parent === null) {
            map.set("parent", null);
        } else {
            map.set("parent", `${parent.cloneID}`);
        }
        if (children.length > 0) {
            map.set("hasChildren", "true");
        } else {
            map.set("hasChildren", "false");
        }
        map.set("rootID", `${this.getRoot().cloneID}`);
        map.set("sampleSource", `'${sampleSource}'`);
        if (coordinates !== null) {
            map.set("coordinates", `'${coordinates[0]},${coordinates[1]}'`);
        }
        map.set("state", `'${state}'`);
        map.set("alias", `'${alias}'`);
        return map;
    }

    getRoot() {
        let p = this;
        while (p.parent != null) {
            p = p.parent;
        }
        return p;
    }

    addChild(c) {
        if (!c.constructor.name === this.constructor.name) {
            throw "IncompatibleClassChangeError();";
        }
        if (c.sampleSource !== sampleSource) {
            throw "IllegalArgumentException();"
        }
        c.parent = this;
        this.children.push(c);
    }

    save2DB() {
        const tableName = CLONEID.getTableNameForClass(this.constructor.name);
        this.informUser();
        for (const c of this.children) {
            c.save2DB();
        }
        const cloneid = new CLONEID();
        cloneid.connect();
        const existingid = this.isInDB(tableName, cloneid);
        const map = this.getDBformattedAttributesAsMap();
        if (existingid === null) {
            let addstmt = "INSERT INTO " + tableName + "(";
            let valstmt = " VALUES(";
            for (const [key, value] of map.entries()) {
                addstmt += `${key}, `;
                valstmt += `${value}, `;
            }
            addstmt = Helper.replaceLast(addstmt, ",", ")");
            valstmt = Helper.replaceLast(valstmt, ",", ")");
            addstmt += valstmt;
            const prest = cloneid.getConnection().prepareStatement(addstmt, Statement.RETURN_GENERATED_KEYS);
            prest.executeUpdate();
            const rs = prest.getGeneratedKeys();
            rs.next();
            this.cloneID = rs.getInt(1);
            const serp = new SerializeProfile_MySQL(this.cloneID, this.constructor.name);
            serp.writeProfile2DB(cloneid.getConnection(), profile);
        } else {
            this.cloneID = existingid;
            this.redundant = true;
        }
        if (this.children.length > 0) {
            for (const c of this.children) {
                const updateSTmt = "UPDATE " + tableName + " SET parent="
                    + `${this.cloneID}, rootID=${this.getRoot().cloneID} WHERE cloneID=${c.cloneID}`;
                cloneid.getStatement().executeUpdate(updateSTmt);
            }
            const updateSTmt = "UPDATE " + tableName + " SET hasChildren=true WHERE cloneID=" + cloneID;
            cloneid.getStatement().executeUpdate(updateSTmt);
        }
        cloneid.close();
        if (this.parent === null && countRedundant() > 0) {
            console.log(countRedundant() + " clones already existed in database and were not saved again.");
        }
    }

    informUser() {
        const spfreq = Helper.count(this.getChildrensSizes(), 0.001);
        if (spfreq.size > 0) {
            console.log("Clones scheduled for saving to database:");
            for (const [key, value] of spfreq.entries()) {
                console.log(`${value} clone(s) of size ${key}`);
            }
        }
    }

    isInDB(tableName, db) {
        const hash = Arrays.deepHashCode(profile.getValues());
        const selstmt = `SELECT cloneID from ${tableName} where abs(size-${this.size})<${PRECISION} and profile_hash=${hash} AND whichPerspective='${this.constructor.name}' AND sampleSource='${sampleSource}';`;
        const rs = db.getStatement().executeQuery(selstmt);
        if (rs.next()) {
            return rs.getInt(1);
        }
        return null;
    }

    getID() {
        return this.cloneID;
    }

    setProfile(p) {
        this.profile = p;
    }

    getSize() {
        return this.size;
    }

    setParent(clone) {
        if (sampleSource !== clone.sampleSource) {
            throw new Error('IllegalArgumentException');
        }
        this.parent = clone;
    }

    getParent() {
        return parent;
    }

    toString() {
        const p = new Perspectives(this.constructor.name);
        const c = CloneColumnPrefix.getValue(p);
        const ret = CloneColumnPrefix.getValue(p) + `_${this.size}_ID${this.cloneID}`;
        return ret;
    }

    getChild(size) {
        for (const c of this.children) {
            if (c.size === size) {
                return c;
            }
        }
        return null;
    }

    getChildrensSizes() {
        const s = new Array(children.length);
        for (let i = 0; i < s.length; i++) {
            s[i] = children[i].size;
        }
        return s;
    }

    setID(cloneID2) {
        this.cloneID = cloneID2;
    }

    setChildrenIDs(childrenIDs) {
        this.childrenIDs = childrenIDs;
    }

    getSampleSource() {
        return sampleSource;
    }

    getChildrenIDs() {
        return this.childrenIDs;
    }

    getCoordinates() {
        return coordinates;
    }

    setCoordinates(x, y) {
        this.coordinates = [x, y];

        for (const c of this.children) {
            c.setCoordinates(x, y);
        }
    }

    countRedundant() {
        let cnt = 0;
        if (this.redundant) {
            cnt = 1;
        }
        for (const c of this.children) {
            cnt += c.countRedundant();
        }
        return cnt;
    }

    getPerspective(whichP) {
    }
}

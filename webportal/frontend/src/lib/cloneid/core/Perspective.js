import { Clone } from './Clone';

export class Perspective extends Clone {
    constructor(f, sampleName)
    {
        super(f, sampleName);
    }

    origin = '';

    getDBformattedAttributesAsMap() {
        let map = super.getDBformattedAttributesAsMap();
        map.put("whichPerspective", "'" + this.constructor.name + "'");
        map.put("origin", "'" + this.origin + "'");
        return map;
    }

    addChild(c) {
        if (!c.constructor.equals(this.constructor)) {
            throw  "IncompatibleClassChangeError();";
        }
        if (!(c.origin === this.origin)) {
            throw  "Perspective::addChild(c)";
        }
        c.parent = this;
        this.children.add(c);
    }
    setParent(clone) {
        if (!(this.origin === clone.origin)) {
            throw "Perspective::setParent(clone)";
        }
        this.parent = clone;
    }

    isInDB(tableName, db) {
        const hash = Arrays.deepHashCode(profile.getValues());
        const selstmt = `SELECT cloneID from ${tableName} where abs(size-${this.size})<${Clone.PRECISION}
            and profile_hash=${hash} AND whichPerspective='${this.constructor.name}' AND origin='${origin}';`;
        const rs = db.getStatement().executeQuery(selstmt);
        if (rs.next()) {
            return rs.getInt(1);
        }
        return null;
    }

    loadFromDB() {
        throw "Perspective.js loadFromDB"; 
    }
}

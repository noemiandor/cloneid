import { Genome } from '../core/utils/Genome';
import { Helper } from '../core/utils/Helper';
import { Perspectives } from '../core/utils/Perspectives';
import { Profile } from '../core/utils/Profile';
import { Transcriptome } from '../core/utils/Transcriptome';
import { CLONEID } from './CLONEID';
import { QueryManager } from './QueryManager';

String.prototype.hashCode = function() {
    var hash = 0, i, chr;
    if (this.length === 0) return hash;
    for (i = 0; i < this.length; i++) {
        chr   = this.charCodeAt(i);
        hash  = ((hash << 5) - hash) + chr;
        hash |= 0;
    }
    return hash;
};


export class SerializeProfile_MySQL {

    static #TABLE_PLACEHOLDER = "XX";
	static #CLONEID_PLACEHOLDER = "YY";

	#wRITE_PROFILE_LOCI_SQL = "INSERT INTO Loci(content, hash) VALUES(?, ?)";
	#rEAD_PROFILE_LOCI_SQL = "SELECT content FROM Loci WHERE id = ?";
	#wRITE_PROFILE_SQL = "UPDATE XX SET profile= ?, profile_hash= ?, profile_loci=? WHERE cloneID=YY";
	#rEAD_PROFILE_SQL = "SELECT profile,whichPerspective,profile_loci FROM XX WHERE cloneID = YY";
	#clone = 0;

    constructor(cloneID, cloneClass) {
        this.wRITE_PROFILE_LOCI_SQL = "INSERT INTO Loci(content, hash) VALUES(?, ?)";
        this.rEAD_PROFILE_LOCI_SQL = "SELECT content FROM Loci WHERE id=?";
        this.wRITE_PROFILE_SQL = "UPDATE XX SET profile=?, profile_hash=?, profile_loci=? WHERE cloneID=YY";
        this.rEAD_PROFILE_SQL = "SELECT profile,whichPerspective,profile_loci FROM XX WHERE cloneID=YY";

        this.clone = cloneID;
        const tableName = CLONEID.getTableNameForClass(cloneClass);

		this.wRITE_PROFILE_SQL = this.wRITE_PROFILE_SQL.replace(SerializeProfile_MySQL.#TABLE_PLACEHOLDER, tableName);
		this.wRITE_PROFILE_SQL = this.wRITE_PROFILE_SQL.replace(SerializeProfile_MySQL.#CLONEID_PLACEHOLDER, cloneID);

		this.rEAD_PROFILE_SQL = this.rEAD_PROFILE_SQL.replace(SerializeProfile_MySQL.#TABLE_PLACEHOLDER, tableName);
		this.rEAD_PROFILE_SQL = this.rEAD_PROFILE_SQL.replace(SerializeProfile_MySQL.#CLONEID_PLACEHOLDER, cloneID+"");
    }

    /**
     * Saves profile to DB
     * @param {Connection} conn
     * @param {Profile} object
     * @throws {Exception}
     */
    async writeProfile2DB(conn, object) {
        const hash = JSON.stringify(object.getLoci()).hashCode();
        let pstmt = await conn.prepareStatement(this.wRITE_PROFILE_LOCI_SQL, Statement.RETURN_GENERATED_KEYS);
        
        const lociBytes = Helper.string2byte(object.getLoci());
        pstmt.setBytes(1, lociBytes);
        pstmt.setInt(2, hash);
        let lociID = -1;
        
        try {
            await pstmt.executeUpdate();
            const rs = await pstmt.getGeneratedKeys();
            rs.next();
            lociID = rs.getInt(1);
        } catch
        {
            pstmt = await conn.prepareStatement("SELECT id FROM Loci WHERE hash = " + hash);
            const rs = await pstmt.executeQuery();
            rs.next();
            lociID = rs.getInt(1);
        }

        pstmt = await conn.prepareStatement(this.wRITE_PROFILE_SQL);
        pstmt.setInt(2, JSON.stringify(object.getValues()).hashCode());
        pstmt.setInt(3, lociID);
        pstmt.setBytes(1, Helper.double2byte(object.getValues()));
        await pstmt.executeUpdate();

        pstmt.close();
    }


    /**
     * Loads profile from DB
     * @param {Connection} conn
     * @returns {Profile}
     * @throws {Exception}
     */
    async readProfileFromDB(conn) {
        let stmt = this.rEAD_PROFILE_SQL;
        let rs = await QueryManager.executeQuery(stmt);
        rs.next();
        let object = Helper.byte2double(rs.getBytes(1));
        let perspective = rs.getString(2);
        let lociID = rs.getInt(3);

        stmt = this.rEAD_PROFILE_LOCI_SQL;
        stmt = stmt.replace('?', lociID.toString());
        rs = await QueryManager.executeQuery(stmt);
        rs.next();
        let loci = Helper.byte2String(rs.getBytes(1));
        let p = null;
        if (perspective === Perspectives.Identity) {
            p = new Profile(loci);
        } else if (
            perspective === Perspectives.GenomePerspective ||
            perspective === Perspectives.KaryotypePerspective ||
            perspective === Perspectives.ExomePerspective
        ) {
            p = new Genome(loci);
        } else if (perspective === Perspectives.TranscriptomePerspective) {
            p = new Transcriptome(loci);
        } else if (perspective === Perspectives.MorphologyPerspective) {
            p = new Profile(loci);
        }
        
        for (let i = 0; i < object.length; i++) {
            p.modify(i, object[i]);
        }
        return p;
    }
}

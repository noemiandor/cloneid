package database;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import java.sql.SQLIntegrityConstraintViolationException;

import core.utils.Helper;
import core.utils.DoubleArraySerializer;
import core.utils.Genome;
import core.utils.Perspectives;
import core.utils.Profile;
import core.utils.Transcriptome;

/**
 * Interacts with MySql DB, by saving and loading the profile of a clone.
 * @author noemi
 *
 */
public class SerializeProfile_MySQL {
	static final CharSequence TABLE_PLACEHOLDER = "XX";
	private static final CharSequence CLONEID_PLACEHOLDER = "YY";

	private String wRITE_PROFILE_LOCI_SQL = "INSERT INTO Loci(content, hash) VALUES(?, ?)";

	private String rEAD_PROFILE_LOCI_SQL = "SELECT content FROM Loci WHERE id = ?";

	private String wRITE_PROFILE_SQL = "UPDATE XX SET profile= ?, profile_hash= ?, profile_loci=? WHERE cloneID=YY";

	private String rEAD_PROFILE_SQL = "SELECT profile,whichPerspective,profile_loci FROM XX WHERE cloneID = YY";


	static Map<Integer, String[]> s_cmap = new HashMap<Integer, String[]>();
	static Map<Integer, Integer> saved_loci_set = new HashMap<Integer, Integer>();
	static Map<Integer, Integer> saved_profile_set = new HashMap<Integer, Integer>();

	public SerializeProfile_MySQL(int cloneID, String cloneClass) {
		String tableName = CLONEID.getTableNameForClass(cloneClass);
		this.wRITE_PROFILE_SQL = this.wRITE_PROFILE_SQL.replace(TABLE_PLACEHOLDER, tableName);
		this.wRITE_PROFILE_SQL = this.wRITE_PROFILE_SQL.replace(CLONEID_PLACEHOLDER, cloneID + "");

		this.rEAD_PROFILE_SQL = this.rEAD_PROFILE_SQL.replace(TABLE_PLACEHOLDER, tableName);
		this.rEAD_PROFILE_SQL = this.rEAD_PROFILE_SQL.replace(CLONEID_PLACEHOLDER, cloneID + "");
	}

	/**
	 * Saves profile to DB
	 * @param conn
	 * @param object
	 * @throws Exception
	 */
	public void writeProfile2DB(Connection conn, Profile object) throws Exception {

		String[] loci = object.getLoci();

		int hash = Arrays.deepHashCode(loci);
		Integer SavedLociId = SerializeProfile_MySQL.saved_loci_set.get(hash);
		int lociID = -1;
		if (SavedLociId == null) {
			PreparedStatement pstmt = conn.prepareStatement(wRITE_PROFILE_LOCI_SQL, Statement.RETURN_GENERATED_KEYS);
			// Profile loci
			pstmt.setBytes(1, Helper.string2byte(loci));
			pstmt.setInt(2, hash);
			try {
				pstmt.executeUpdate();
				ResultSet rs = pstmt.getGeneratedKeys();
				rs.next();
				lociID = rs.getInt(1);
			} catch (SQLIntegrityConstraintViolationException e) {
				pstmt = conn.prepareStatement("SELECT id FROM Loci WHERE hash = " + hash);
				ResultSet rs = pstmt.executeQuery();
				rs.next();
				lociID = rs.getInt(1);
			}
			SerializeProfile_MySQL.saved_loci_set.put(hash, lociID);
			System.out.printf("ADDED LOCI:%d:%d:%d\n", lociID, String.join(":", loci).length(), hash);
			pstmt.close();
		}else{
			lociID = SavedLociId.intValue();
			// System.out.printf("SAVED LOCI:%d:%d:%d\n", lociID, 0, hash);
		}


		// Profile
		Double[] values = object.getValues();
		int hash_profile = Arrays.deepHashCode(values);
		byte[] compressedValues1 = DoubleArraySerializer.serialize(values);
		Integer SavedProfile = SerializeProfile_MySQL.saved_profile_set.get(hash_profile);
		if (SavedProfile == null) {
			PreparedStatement pstmt = conn.prepareStatement(wRITE_PROFILE_SQL);
			pstmt.setBytes(1, compressedValues1);
			pstmt.setInt(2, hash_profile);
			pstmt.setInt(3, lociID);
			pstmt.executeUpdate();
			pstmt.close();
		}
	}

	private Profile createProfile(String perspective, String[] loci, Double[] object) {
		Profile p = null;
		switch (Perspectives.valueOf(perspective)) {
			case Identity:
			case MorphologyPerspective:
				p = new Profile(loci);
				break;
			case GenomePerspective:
			case KaryotypePerspective:
			case ExomePerspective:
				p = new Genome(loci);
				break;
			case TranscriptomePerspective:
				p = new Transcriptome(loci);
				break;
			default:
				throw new IllegalArgumentException("Unknown perspective: ");
		}

		p.setValues(object);

		return p;
	}

	/**
	 * Loads profile from DB
	 *
	 * @param conn
	 * @return
	 * @throws Exception
	 */
	public Profile readProfileFromDB(Connection conn) throws Exception {
		// Read profile values
		PreparedStatement pstmt = conn.prepareStatement(rEAD_PROFILE_SQL);
		ResultSet rs = pstmt.executeQuery();
		rs.next();
		Double[] object = DoubleArraySerializer.deserialize(rs.getBytes(1));
		String perspective = rs.getString(2);
		int lociID = rs.getInt(3);
		rs.close();

		String[] loci = SerializeProfile_MySQL.s_cmap.get(lociID);

		if (loci == null) {
			// Read profile loci
			pstmt = conn.prepareStatement(rEAD_PROFILE_LOCI_SQL);
			pstmt.setInt(1, lociID);
			rs = pstmt.executeQuery();
			rs.next();
			loci = Helper.byte2String(rs.getBytes(1));
			SerializeProfile_MySQL.s_cmap.put(lociID, loci);
			pstmt.close();
		}

		return createProfile(perspective, loci, object);
	}

}

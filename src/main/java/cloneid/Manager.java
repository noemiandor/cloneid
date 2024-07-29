package cloneid;

import java.io.File;
import core.Clone;
import core.GenomePerspective;
import core.MorphologyPerspective;
import core.Perspective;
import core.TranscriptomePerspective;
import core.utils.Helper;
import core.utils.Perspectives;
import core.utils.Profile;
import database.CLONEID;
import services.YamlReaderService;
import services.DatabaseService;
import java.sql.ResultSet;
import java.util.HashMap;
import java.util.Map;
// import static java.lang.Integer.parseInt;

/**
 * Static class providing user-interface methods to query the database. 
 * @author noemi
 *@TODO: select only clone of max ID, not based on hasChildren=true
 */
public final class Manager {

	private static Map<String, Clone> gatherForDisplay(String selstmt, String cloneID_or_sampleName, Perspectives which) throws Exception {
		CLONEID cloneid= new CLONEID();
		cloneid.connect();

		ResultSet rs =cloneid.getStatement().executeQuery(selstmt);
		Map<String, Clone> cloneSizes=new HashMap<String, Clone>();
		rs.next();
		Clone parent= cloneid.getClone(rs.getInt("cloneID"), which);
		int[] kids = cloneid.getChildrenForParent(parent.getID(), which);
		if(kids!=null){
			for(int kid:kids){
				Clone clone=cloneid.getClone(kid,which);
				/*
				if(Math.abs(clone.getParent().getSize()-parent.getSize())>0.0001){
					continue;//Don't cover multiple generations
				}
				*/
				cloneSizes.put(clone.toString(), clone);
			}
		}else{
			cloneSizes.put(cloneID_or_sampleName+"", parent); //@TODO: do not assume size=1 --> get value from DB
		}
		cloneid.close();
		return(cloneSizes);
	}

	public static Map<String, Profile> profiles(String sampleName, Perspectives which, boolean includeRoot) throws Exception {
		String selstmt="SELECT size,cloneID from "+which.getTableName()+" where hasChildren=true AND origin=\'"+sampleName+"\' AND whichPerspective=\'"+which+"\' ORDER BY size DESC;"; 
		return(gatherProfiles(selstmt,which,includeRoot));
	}

	public static Map<String, Profile> profiles(int cloneID, Perspectives which, boolean includeRoot) throws Exception {
		String selstmt="SELECT size,cloneID from "+which.getTableName()+" where hasChildren=true AND cloneID="+cloneID+" AND whichPerspective=\'"+which+"\' ORDER BY size DESC;"; 
		return(gatherProfiles(selstmt,which,includeRoot));
	}

	public static Map<String, Profile> profile(int cloneID, Perspectives which) throws Exception {
		Map<String,Profile> profiles=new HashMap<String,Profile>();
		CLONEID cloneid= new CLONEID();
		cloneid.connect();

		Clone clone=cloneid.getClone(cloneID,which);
		profiles.put(clone.toString(), clone.getProfile());
		cloneid.close();

		return(profiles);
	}

   private static Map<String, Profile> gatherProfiles(String selstmt, Perspectives which, boolean includeRoot) throws Exception {
		CLONEID cloneid = new CLONEID();
		cloneid.connect();
		Map<String, Profile> profiles = new HashMap<>();
		ResultSet rs = cloneid.getStatement().executeQuery(selstmt);
		if (rs.next()) {
			Clone root = cloneid.getClone(rs.getInt("cloneID"), which);

			int[] kids = cloneid.getChildrenForParent(root.getID(), which);
			for (int kid : kids) {
				Clone clone = cloneid.getClone(kid, which);
				profiles.put(clone.toString(), clone.getProfile());
			}
			if (includeRoot) {
				profiles.put(root.toString(), root.getProfile());
			}
		}
		return profiles;
    }

	public static Map<String, Clone> display(int cloneID, Perspectives which) throws Exception{
		String selstmt="SELECT parent,cloneID,size from "+which.getTableName()+" where cloneID="+cloneID+" AND whichPerspective=\'"+which+"\' ORDER BY size DESC;";
		Map<String, Clone> cloneSizes=gatherForDisplay(selstmt,cloneID+"", which);
		return(cloneSizes);
	}

	public static Map<String, Clone> display(String sampleName, Perspectives which) throws Exception{
		String selstmt="SELECT cloneID,size from "+which.getTableName()+" where parent IS NULL AND hasChildren=true AND origin=\'"+sampleName+"\' AND whichPerspective=\'"+which+"\' ORDER BY size DESC;";
		Map<String, Clone> cloneSizes=gatherForDisplay(selstmt,sampleName, which);
		return(cloneSizes);
	}

	public static double[][] compare(int cloneID1, Perspectives which1, int cloneID2, Perspectives which2) throws Exception {
		CLONEID db= new CLONEID();
		db.connect();

		Clone c1=db.getClone(cloneID1, which1);	
		Clone c2=db.getClone(cloneID2, which2);	

		double[][] out=new double[][]{Helper.toDouble(c1.getProfile().getValues()), Helper.toDouble(c2.getProfile().getValues())};		
		return(out);
	}

	private static void createSchema(YamlReaderService yamlReader, Boolean forceCreateSchema) {

		final String STDERR_PREFIX = "JAVADB: ";
		final String NO_CHANGES_MADE_TO_DB = "No changes made to database: " + yamlReader.getConfig().getMysqlConnection().get("database");

		DatabaseService dbService = new DatabaseService(
				yamlReader.getConfig().getMysqlConnection().get("host"),
				yamlReader.getConfig().getMysqlConnection().get("port"),
				yamlReader.getConfig().getMysqlConnection().get("user"),
				yamlReader.getConfig().getMysqlConnection().get("password"),
				yamlReader.getConfig().getMysqlConnection().get("database"),
				yamlReader.getConfig().getMysqlConnection().get("schemaScript"),
				yamlReader.getConfig().getDbTables(),
				forceCreateSchema
		);

		try {
			dbService.createSchema();
		} catch (Exception e) {
			System.err.println(STDERR_PREFIX + e.getMessage());
			System.err.println(STDERR_PREFIX + "Unable to create CLONEID Schema");
			System.err.println(STDERR_PREFIX + NO_CHANGES_MADE_TO_DB);
			System.err.println(STDERR_PREFIX + "Please check username, password and/or database permissions");
		}

	}

    // public static String extractID(String cloneString) {
    //     String[] parts = cloneString.split("ID");
    //     if (parts.length >= 2) {
    //         return parts[1];
    //     } else {
    //         return parts[0];
    //     }
    // }
    // public static void main(String[] args) {
    //     try {
    //         Map<String, Clone> X = Manager.display("SNU-668", Perspectives.GenomePerspective);
    //         for (Clone clone : X.values()) {
    //             System.out.println(clone.toString());
    //             String Y = Manager.extractID(clone.toString());
    //             Map<String, Profile> Z = Manager.profiles(parseInt(Y), Perspectives.GenomePerspective, false);
    //             System.out.println(Z);
    //         }
    //     } catch (Exception e) {
    //         e.printStackTrace();
    //     }
    // }
	// public static void _main(String[] args) {
	// 	try {
	// 	} catch (Exception e) {
	// 		e.printStackTrace();
	// 	}
	// }
}

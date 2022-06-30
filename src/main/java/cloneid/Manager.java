package cloneid;

import java.io.File;
import core.Clone;
import core.GenomePerspective;
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
		int[] kids = cloneid.getChildrenForParent(parent.getID(), which, true);
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
			cloneSizes.put(parent.toString(), parent); //@TODO: do not assume size=1 --> get value from DB
		}
		cloneid.close();
		return(cloneSizes);
	}

	public static Map<String, Profile> profiles(String sampleName, Perspectives which, boolean includeRoot) throws Exception {
		String tN = CLONEID.getTableNameForClass(which.name());
		String selstmt="SELECT size,cloneID from "+tN+" where hasChildren=true AND sampleSource=\'"+sampleName+"\' AND whichPerspective=\'"+which+"\' ORDER BY size DESC;"; 
		return(gatherProfiles(selstmt,which,includeRoot));
	}

	public static Map<String, Profile> profiles(int cloneID, Perspectives which, boolean includeRoot) throws Exception {
		String tN = CLONEID.getTableNameForClass(which.name());
		String selstmt="SELECT size,cloneID from "+tN+" where hasChildren=true AND cloneID="+cloneID+" AND whichPerspective=\'"+which+"\' ORDER BY size DESC;"; 
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
		CLONEID cloneid= new CLONEID();
		cloneid.connect();

		ResultSet rs =cloneid.getStatement().executeQuery(selstmt);
		rs.next();
		Clone root=cloneid.getClone(rs.getInt("cloneID"),which);
		
		int[] kids = cloneid.getChildrenForParent(root.getID(), which);
		Map<String,Profile> profiles=new HashMap<String,Profile>();
		for(int kid:kids){
			Clone clone=cloneid.getClone(kid,which);
			profiles.put(clone.toString(), clone.getProfile());
		}
		cloneid.close();

		if(includeRoot){
			profiles.put(root.toString(), root.getProfile());
		}

		return(profiles);
	}

	public static Map<String, Clone> display(int cloneID, Perspectives which) throws Exception{
		String tN = CLONEID.getTableNameForClass(which.name());
		String selstmt="SELECT parent,cloneID,size from "+tN+" where cloneID="+cloneID+" AND whichPerspective=\'"+which+"\' ORDER BY size DESC;";
		Map<String, Clone> cloneSizes=gatherForDisplay(selstmt,cloneID+"", which);
		return(cloneSizes);
	}

	public static Map<String, Clone> display(String sampleName, Perspectives which) throws Exception{
		String tN = CLONEID.getTableNameForClass(which.name());
		String selstmt="SELECT cloneID,size from "+tN+" where parent IS NULL AND hasChildren=true AND sampleSource=\'"+sampleName+"\' AND whichPerspective=\'"+which+"\' ORDER BY size DESC;";
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

	public static void main(String[] args) {
		/*
			String[] sName=args[0].split("\\.");
			try {
				display("Rand1_NCI-N87NCI-N87", Perspectives.Identity);
				System.out.println("tmp");
			} catch (Exception e2) {
				e2.printStackTrace();
			}
			try {
				Map<String, Clone> x = display("LGG174T" , Perspectives.valueOf("Identity"));
				GenomePerspective gp=new GenomePerspective(new File("/Users/noemi/Projects/PMO/InferringMultiSamplePhylo/data/Kyoto-LGG/processed_against_LGG174N//A05_170412_expands/LGG174T2.sps"), "CN_Estimate");
				gp.setCoordinates(4.0, 3.0);
				Identity gp=new Identity(new File(args[0]), "CN_Estimate", new File(args[1]));
				gp.save2DB();
				System.out.println(gp.getCoordinates()[0]);;
				System.out.println(gp.toString());
			} catch (Exception e) {
				e.printStackTrace();
			}

				try {
					Map<String, Profile> ip=profiles("KATOIII", Perspectives.TranscriptomePerspective,false);
				} catch (Exception e1) {
					e1.printStackTrace();
				}


			try {
				compare(3, Perspectives.GenomePerspective, 4, Perspectives.GenomePerspective);
			} catch (Exception e1) {
				e1.printStackTrace();
			}
		*/

			
//		YamlReaderService yamlReader = new YamlReaderService();
//		Boolean forceCreateSchema = false;
//
//		for (String arg : args) {
//
//			if (arg.equals("-c") || arg.equals("--create-schema") || arg.equals("-f") || arg.equals("--force-create-schema")) {
//
//				if (arg.equals("-f") || arg.equals("--force-create-schema")) { forceCreateSchema = true; }
//				createSchema(yamlReader, forceCreateSchema);
//
//			} 
//
//		}
		
		try {
			/*
				Map<String, Clone> tmp = display("SNU-16", Perspectives.Identity);
				tmp.values().iterator().next().getPerspective(Perspectives.TranscriptomePerspective);
				Identity p =new Identity(new File("/Users/noemi/Projects/PMO/InferringMultiSamplePhylo/data/Kyoto-LGG/SNParray/LGG174/A06_170603_expands/LGG174T.identity.sps"),"CN_Estimate",new File("/Users/noemi/Projects/PMO/InferringMultiSamplePhylo/data/Kyoto-LGG/SNParray/LGG174/A06_170603_expands/LGG174T.identity.source"));
				Perspective p_ = new TranscriptomePerspective(new File("/Users/noemi/Projects/PMO/MeasuringGIperClone/data/GastricCancerCLs/scRNAseq/B07_180109_LIAYSON/NCI-N87.sps.cbs"),"CN_Estimate");
				p_.save2DB();
				Perspective p =new ExomePerspective(new File(args[0]),"CN_Estimate");
				Perspective p = new TranscriptomePerspective(new File("/Users/noemi/Projects/PMO/MeasuringGIperClone/data/GastricCancerCLs/scRNAseq/B07_180109_LIAYSON/SNU-16.0.07274.sps.cbs"),"Clone_0.07274");
			*/
//			profile(3456, Perspectives.GenomePerspective);
//			Perspective p2 = new GenomePerspective(new File("/Users/noemi/Projects/PMO/MeasuringGIperClone/data/GastricCancerCLs/scDNAseq/E07_180831_clones/HGC-27.sps.cbs"), "CN_Estimate");
//			System.out.println(p2.getChildrensSizes());
			//			p2.save2DB();
			display("KATOIII", Perspectives.TranscriptomePerspective);
//			profiles(119963, Perspectives.TranscriptomePerspective, false);
//			TranscriptomePerspective tmp = new TranscriptomePerspective(new File("/Users/4470246/Projects/PMO/MeasuringGIperClone/data/GastricCancerCLs/scRNAseq/C07_190610_LIAYSON//SNU-16_3.sps.cbs"), "CN_Estimate");
//			TranscriptomePerspective tmp = new TranscriptomePerspective(new File("/Users/4470246/Projects/PMO/MeasuringGIperClone/data/GastricCancerCLs/scRNAseq/C07_190610_LIAYSON//SNU-16_3.0.1914997.sps.cbs"), "Clone_0.191499695181847");
//tmp.save2DB();
		} catch (Exception e) {
			e.printStackTrace();
		}

	}

}

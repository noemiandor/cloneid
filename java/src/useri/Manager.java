package useri;

import java.io.File;
import java.sql.ResultSet;
import java.util.HashMap;
import java.util.Map;

import core.Clone;
import core.GenomePerspective;
import core.Identity;
import core.utils.Helper;
import core.utils.Perspectives;
import core.utils.Profile;
import database.CLONEID;

/**
 * Static class providing user-interface methods to query the database. 
 * @author noemi
 *@TODO: select only clone of max ID, not based on NOT NULL children
 */
public final class Manager {


	
	private static Map<String, Clone> gatherForDisplay(String selstmt, String cloneID_or_sampleName, Perspectives which) throws Exception {
		CLONEID cloneid= new CLONEID();
		cloneid.connect();
		
		ResultSet rs =cloneid.getStatement().executeQuery(selstmt);
		Map<String, Clone> cloneSizes=new HashMap<String, Clone>();
		rs.next();
		String tmp=rs.getString("children");
		Clone parent= cloneid.getClone(rs.getInt("cloneID"), which);
		if(tmp!=null){
			String[] kids=tmp.split(",");
			for(String kid:kids){
				Clone clone=cloneid.getClone(Integer.parseInt(kid),which);
				if(Math.abs(clone.getParent().getSize()-parent.getSize())>0.0001){
					continue;//Don't cover multiple generations
				}
				cloneSizes.put(clone.toString(), clone);
			}
		}else{
			cloneSizes.put(cloneID_or_sampleName+"", parent); //@TODO: do not assume size=1 --> get value from DB
		}
		cloneid.close();
        return(cloneSizes);
	}
	
	public static Map<String, Profile> profiles(String sampleName, Perspectives which, boolean includeRoot) throws Exception {
		String tN = CLONEID.getTableNameForClass(which.name());
		String selstmt="SELECT children,size,cloneID from "+tN+" where children IS NOT NULL AND sampleName=\'"+sampleName+"\' AND whichPerspective=\'"+which+"\' ORDER BY size DESC;"; 
		return(gatherProfiles(selstmt,which,includeRoot));
	}
	
	public static Map<String, Profile> profiles(int cloneID, Perspectives which, boolean includeRoot) throws Exception {
		String tN = CLONEID.getTableNameForClass(which.name());
		String selstmt="SELECT children,size,cloneID from "+tN+" where children IS NOT NULL AND cloneID="+cloneID+" AND whichPerspective=\'"+which+"\' ORDER BY size DESC;"; 
		return(gatherProfiles(selstmt,which,includeRoot));
	}
	
	private static Map<String, Profile> gatherProfiles(String selstmt, Perspectives which, boolean includeRoot) throws Exception {
		CLONEID cloneid= new CLONEID();
		cloneid.connect();

		ResultSet rs =cloneid.getStatement().executeQuery(selstmt);
		rs.next();
		String[] kids=rs.getString("children").split(",");
		Clone root=cloneid.getClone(rs.getInt("cloneID"),which);
		Map<String,Profile> profiles=new HashMap<String,Profile>();
		for(int i =0; i<kids.length; i++){
			String kid=kids[i];
			Clone clone=cloneid.getClone(Integer.parseInt(kid),which);
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
		String selstmt="SELECT children,parent,cloneID,size from "+tN+" where cloneID="+cloneID+" AND whichPerspective=\'"+which+"\' ORDER BY size DESC;";
		Map<String, Clone> cloneSizes=gatherForDisplay(selstmt,cloneID+"", which);
		return(cloneSizes);
	}


	public static Map<String, Clone> display(String sampleName, Perspectives which) throws Exception{
		String tN = CLONEID.getTableNameForClass(which.name());
		String selstmt="SELECT children,cloneID,size from "+tN+" where children IS NOT NULL AND sampleName=\'"+sampleName+"\' AND whichPerspective=\'"+which+"\' ORDER BY size DESC;";
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
	

	
	public static void main(String[] args) {
		String[] sName=args[0].split("\\.");
		try {
			display("Rand1_NCI-N87NCI-N87", Perspectives.Identity);
			System.out.println("tmp");
		} catch (Exception e2) {
			// TODO Auto-generated catch block
			e2.printStackTrace();
		}	
		try {
//			Map<String, Clone> x = display("LGG174T" , Perspectives.valueOf("Identity"));
//			GenomePerspective gp=new GenomePerspective(new File("/Users/noemi/Projects/PMO/InferringMultiSamplePhylo/data/Kyoto-LGG/processed_against_LGG174N//A05_170412_expands/LGG174T2.sps"), "CN_Estimate");
//			gp.setCoordinates(4.0, 3.0);
			Identity gp=new Identity(new File(args[0]), "CN_Estimate", new File(args[1]));
			gp.save2DB();
			System.out.println(gp.getCoordinates()[0]);;
			System.out.println(gp.toString());
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
			try {
				Map<String, Profile> ip=profiles("KATOIII", Perspectives.TranscriptomePerspective,false);
			} catch (Exception e1) {
				// TODO Auto-generated catch block
				e1.printStackTrace();
			}

		
		try {
			compare(3, Perspectives.GenomePerspective, 4, Perspectives.GenomePerspective);
		} catch (Exception e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
	
		try {
			Identity p =new Identity(new File("/Users/noemi/Projects/PMO/MeasuringGIperClone/results/KATOIII.identity.sps.cbs"),"CN_Estimate",new File("/Users/noemi/Projects/PMO/MeasuringGIperClone/results/KATOIII.identity.source"));
//			Perspective p = new GenomePerspective(new File("/Users/noemi/Projects/PMO/MeasuringGIperClone/data/GastricCancerCLs/SNParray/A05_170214_expands/KATOIII.sps.cbs"),"CN_Estimate");
//			Perspective p = new TranscriptomePerspective(new File("/Users/noemi/Projects/PMO/MeasuringGIperClone/data/GastricCancerCLs/scRNAseq/A02_170316_LIAYSON/KATOIII.sps.cbs"),"CN_Estimate");
//			Perspective p = new TranscriptomePerspective(new File("/Users/noemi/Projects/PMO/MeasuringGIperClone/data/GastricCancerCLs/scRNAseq/A02_170316_LIAYSON/KATOIII.46.sps.cbs"),"Clone_0.458");
//			Perspective p = new TranscriptomePerspective(new File("/Users/noemi/Projects/PMO/MeasuringGIperClone/data/GastricCancerCLs/scRNAseq/A02_170316_LIAYSON/KATOIII.54.sps.cbs"),"Clone_0.542");
			p.save2DB();
			display("KATOIII", Perspectives.GenomePerspective);
			display("KATOIII", Perspectives.Identity);

		}  catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

}

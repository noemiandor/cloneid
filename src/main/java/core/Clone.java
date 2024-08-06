package core;

import java.io.File;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import useri.utils.CloneColumnPrefix;
import core.utils.Helper;
import core.utils.Perspectives;
import core.utils.Profile;
import database.CLONEID;
import database.SerializeProfile_MySQL;

/**
 * Objects of instance Clone hold the properties of a population of cells. Cell members of clone have something in common: 
 * be it the clonal expansion that propagated them or simply the fact that they are present in the same biosample (i.e. metapopulation). 
 * Immediate subclasses of Clone have their own corresponding table in the database. 
 * @author noemi
 *
 */
public abstract class Clone {

	protected static final double PRECISION = 0.00000005;

	/**
	 * The fraction of cells from the biosample that have been assigned to this clone (1 if this clone represents the metapopulation). 
	 */
	protected float	size;

	/**
	 * A clone which contains this clone. Clones without a parent shall not persist in the database.
	 * @TODO: parent should be forced to be of same type!
	 */
	protected Clone parent;

	/**
	 * Clones contained within this clone
	 * @TODO: children should be forced to be of same type!
	 */
	protected List<Clone> children;

	/**
	 * The name of the source (a cell line or patient) in which this clone was detected.
	 */
	protected String sampleSource;


	/**
	 * The unique identifier of the clone in the database. Only set once clone is saved to database.
	 */
	protected int cloneID;

	/**
	 * The characteristics unique to this clone.
	 */
	protected Profile profile;

	/**
	 * @TODO: this field should be removed - read entire child as true clone instead in: CLONEID.getClone(...)
	 */
	private int[] childrenIDs;

	/**
	 * The geographical location of the clone
	 */
	protected double[] coordinates;

	/**
	 * True if the clone was already found in the database when trying to save it, false otherwise.
	 */
	private boolean redundant = false;
	
	
	/**
	 * The cell cycle state of the clone
	 */
	private String state;
	
	/**
	 * Nickname of the clone
	 */
	private String alias;


	static Map<String, String> cmap = new HashMap<String, String>();

	/**
	 * Instantiates a clone from:
	 * @param size - the fraction of cells from the biosample that have been assigned to this clone.
	 * @param sampleName - the name of the biosample.
	 * @throws SQLException 
	 */
	public Clone(float size, String sampleName) throws SQLException{
		this.size=size;
		setCellLineOrPatientFor(sampleName);
		children=new ArrayList<Clone>();
	}

	/**
	 * Instantiates a metapopulation along with all its subclones from an ".sps" or an ".sps.cbs" file.
	 * @param outFile - tab-separated file where columns include the clone sizes and each row corresponds to a characteristic of the clone's profile.
	 * @param whichPerspective - the perspective from which this clone is viewed or NULL, if we have the privilege of dealing with the clone's identity
	 * @param parentCloneID - the column name (*_xx) of the parental clone, where xx is its size. If the file doesn't contain the specified column, we will look for a clone with this characteristics in the database
	 * @throws Exception 
	 */
	public Clone(File outFile, Perspectives whichPerspective, String parentCloneID) throws Exception {
		String sampleName =outFile.getName().split("\\.")[0];
		setCellLineOrPatientFor(sampleName);	
		children=new ArrayList<Clone>();
		try{
			this.size=Float.parseFloat(parentCloneID.split("_")[1]); 
		}catch (NumberFormatException e){
			this.size=1; //@TODO: should not be necessary - enforce correct file format
			e.printStackTrace();
		}



		List<String> lines = Files.readAllLines(Paths.get(outFile.getAbsolutePath()), Charset.defaultCharset()); //TODO: Alternative needed if file is too big to be read at once?
		while(lines.get(0).startsWith("#")){
			lines.remove(0); //Remove line starting with #.
		}
		String[] header=lines.get(0).split(Helper.TAB);
		String[] loci=Helper.apply(Helper.sapply(lines.subList(1, lines.size()),"split",Helper.TAB),"get",Helper.firstIndexOf("LOCUS", header));

		//Find clone columns
		List<Integer> cloneI=new ArrayList<Integer>(); //Column indices of clones
		int metaI=Helper.firstIndexOf(parentCloneID, header); //@TODO: ensure root column name has correct format *_number
		if(metaI<0){
			loadFromDB();
		}else{
			this.profile=Clone.getInstance(size, sampleName,whichPerspective,loci).profile;
		}
		for(int sI=0; sI<header.length; sI++){
			if(sI==metaI){
				continue;
			}
			if(header[sI].matches(CloneColumnPrefix.getValue(whichPerspective)+"\\d*_\\d+.*")){
				cloneI.add(sI);
				String[] hfeatures=header[sI].split("_");
				float size=Float.parseFloat(hfeatures[1]); //@TODO: save "_" as part of EXPANDS/LIAYSON interface class
//				size=(float) Math.min(1-PRECISION, size); //Size 1 should be exclusive to root
				Clone p_=Clone.getInstance(size, sampleName,whichPerspective,loci);
				if(hfeatures.length>2){
					p_.state=hfeatures[2];	
				}
				if(hfeatures.length>3){
					p_.alias=hfeatures[3];	
				}
				this.addChild(p_);
			}
		}

		//Read clones' profile  		
		for(int i=1; i<lines.size(); i++){
			String[] cont=lines.get(i).split(Helper.TAB);
			for(int j=0; j<cloneI.size(); j++){
				int cI = cloneI.get(j); //The column index of this clone
				this.children.get(j).getProfile().modify(i-1, Helper.parseDouble(cont[cI]));
			}
			if(metaI>=0){
				this.profile.modify(i-1, Helper.parseDouble(cont[metaI]));
			}
		}


	}

	/**
	 * Reads characteristics of this clone from the database, including: 
	 * - the clone's ID
	 * - its coordinates
	 * - its profile
	 * Clone is selected from the dataset based on its size and the sample to which it belongs.
	 * @TODO: this will not work if two or more clones have same size --> get rid of dependencies on this method, instead use only CLONEID.getClone(..) for loading objects from DB 
	 * @throws Exception
	 */
	protected void loadFromDB() throws Exception {
		CLONEID db= new CLONEID();
		db.connect();
		//@TODO: there's a risk here of overlapping clone sizes and wrong assignment of clone members
		String selstmt="SELECT cloneID,coordinates from "+CLONEID.getTableNameForClass(this.getClass().getSimpleName())+" where abs(size-"+size+")<"+PRECISION+" AND whichPerspective=\'"+this.getClass().getSimpleName()+"\' AND sampleSource=\'"+sampleSource+"\';";
		ResultSet rs =db.getStatement().executeQuery(selstmt);
		rs.next();
		this.cloneID=rs.getInt("cloneID");
		try{
			this.coordinates=Helper.string2double(rs.getString("coordinates").split(","));
		}catch (NullPointerException e){
			//			No coordinates available for this clone
		}
		SerializeProfile_MySQL serp=new SerializeProfile_MySQL(cloneID,this.getClass().getSimpleName());
		this.profile=serp.readProfileFromDB(db.getConnection());
		//		this.children=rs.getString("children"); //@TODO: do children need to be loaded?
		//		this.parent=Clone.getInstance(size, selstmt, which, nMut); //@TODO: does parent need to be loaded?

		db.close();

	}

	public Profile getProfile() {
		return profile;
	}

	
	private void setCellLineOrPatientFor(String origin2) throws SQLException {
		
		if(!this.getClass().equals(Identity.class)) {
			((Perspective)this).origin = origin2;
		}
		String cellLine = Clone.cmap.get(origin2);
		if (cellLine != null) {
			this.sampleSource = cellLine;
			return;
		}	
		CLONEID db= new CLONEID();
		db.connect();

		String selstmt="SELECT cellLine from Passaging where id = '"+origin2+"';";
		ResultSet rs =db.getStatement().executeQuery(selstmt);
		rs.next();
		cellLine = rs.getString("cellLine");
		this.sampleSource = cellLine;
		Clone.cmap.put(origin2, cellLine);
		db.close();
	} 
	
	/**
	 * Retrieves the properties of this clone to be saved in the database.
	 * @return a map of the attribute values in a database-compatible format, with keys naming the table columns in the database.
	 */
	protected Map<String, String> getDBformattedAttributesAsMap(){
		Map<String, String> map =new HashMap<String, String>();
		map.put( "size", size+"");
		if(parent==null){
			map.put( "parent",null);
		}else{
			map.put( "parent", ""+parent.cloneID);
		}

		if(children.size()>0){
//			String kids="\'";
//			for (Clone kid: children){
//				kids+=kid.cloneID+",";
//			}
//			kids=Helper.replaceLast(kids, ",", "\'");
//			map.put( "children", kids);
			map.put( "hasChildren", "true");
		}else{
//			map.put( "children", null);
			map.put( "hasChildren", "false");
		}

		map.put( "rootID", getRoot().cloneID+"");
		map.put( "sampleSource", "\'"+sampleSource+"\'");
		if(coordinates!=null){
			map.put("coordinates", "\'"+coordinates[0]+","+coordinates[1]+"\'");
		}
		map.put("state", "\'"+state+"\'");
		map.put("alias", "\'"+alias+"\'");
		return(map);
	}

	/**
	 * @return The metapopulation within which this clone was found.
	 */
	private Clone getRoot() {
		Clone p=this;
		while(p.parent!=null){
			p=p.parent;
		}
		return(p);
	}


	/**
	 * Adds clone @child contained within this clone to this clone's children. This method also sets the parent of @child to reference this clone.  
	 * @param c - the clone contained within this clone. 
	 */
	protected void addChild(Clone c){
		//children and parent must be of the same type: e.g. an identity's parent can't be a perspective
		if(!c.getClass().equals(this.getClass())){
			throw new IncompatibleClassChangeError();
		}
		if(!c.sampleSource.equals(sampleSource)){
			throw new IllegalArgumentException();
		}
//		//child can't be larger than parent
//		if(c.size>=this.size){
//			throw new IllegalArgumentException("Child clone has to be smaller than parent!");
//		}
		c.parent=this; //Counting on call-by-reference effect here to ensure every child has this clone as parent
		children.add(c);
	}


	/**
	 * Saves this clone along with all its children into the database. 
	 * Importantly, this is the only method within which a clone's ID (@cloneID) can be assigned as the value of the primary key used to enter the clone into the database.
	 * @throws Exception 
	 * @TODO: this method must guarantee that a clone without a parent will not persist in the database
	 * @TODO: this method must first remove from the database clones associated with the same perspective on this biosample, before entering the new clones.  
	 */
	public void save2DB() throws Exception{

		String tableName=CLONEID.getTableNameForClass(this.getClass().getSimpleName());
		informUser();
		for(Clone c: children){
			c.save2DB();
		}

		CLONEID cloneid= new CLONEID();
		cloneid.connect();

		//Check if clone doesn't exist yet in DB
		Integer existingid=isInDB(tableName, cloneid);
		Map<String,String> map = this.getDBformattedAttributesAsMap();
		if(existingid==null){
			//Formulate INSERT statement
			String addstmt = "INSERT INTO " + tableName+ "(";
			String valstmt=" VALUES(";
			for(Entry<String, String> kv : map.entrySet()){
				addstmt+=""+kv.getKey()+", ";
				valstmt+=""+kv.getValue()+", "; 
			}
			addstmt=Helper.replaceLast(addstmt,",",")");
			valstmt=Helper.replaceLast(valstmt,",",")");
			addstmt+=valstmt;

			//Save all attributes except profile
			PreparedStatement prest= cloneid.getConnection().prepareStatement(addstmt, Statement.RETURN_GENERATED_KEYS);
			prest.executeUpdate();
			ResultSet rs = prest.getGeneratedKeys();
			rs.next();
			this.cloneID = rs.getInt(1);

			//Save profile
			SerializeProfile_MySQL serp=new SerializeProfile_MySQL(this.cloneID,this.getClass().getSimpleName());
			serp.writeProfile2DB(cloneid.getConnection(), profile);
		}else{
			this.cloneID=existingid;
			this.redundant=true;
		}

		//IF this is a parent - update the children to reference the parent and vice versa
		if(children.size()>0){
			for(Clone c: children){
				String updateSTmt = "UPDATE " + tableName + " SET parent=" 
						+ this.cloneID+ ", rootID="+this.getRoot().cloneID+" WHERE cloneID=" + c.cloneID;
				cloneid.getStatement().executeUpdate(updateSTmt);
			}
//			String updateSTmt = "UPDATE " + tableName + " SET children="+ map.get("children")+" WHERE cloneID=" + cloneID;
			String updateSTmt = "UPDATE " + tableName + " SET hasChildren=true WHERE cloneID=" + cloneID;
			cloneid.getStatement().executeUpdate(updateSTmt);
		}

		cloneid.close();
		
		//How many clones were not saved:
		if(this.parent==null && countRedundant()>0){
			System.out.println(countRedundant()+" clones already existed in database and were not saved again.");
		}

	}

	private void informUser() {
		Map<Double,Integer> spfreq=Helper.count(getChildrensSizes(),0.001);
		if(spfreq.size()>0){
			System.out.println("Clones scheduled for saving to database:");
			for(Entry<Double, Integer> e : spfreq.entrySet()){
				System.out.println(""+e.getValue()+" clone(s) of size "+e.getKey()+"");
			}
		}
	}

	/**
	 * Check if clone exists yet in DB. If so, return the clone's ID
	 */
	protected Integer isInDB(String tableName, CLONEID db) throws Exception {
		int hash = Arrays.deepHashCode(profile.getValues());
		//@TODO: risk that clone is falsely classified as already existent even though it is not <=> hash is non-unique for long arrays
		String selstmt="SELECT cloneID from "+tableName+" where abs(size-"+this.size+")<"+PRECISION+" and profile_hash="+hash+" AND whichPerspective=\'"+this.getClass().getSimpleName()+"\' AND sampleSource=\'"+sampleSource+"\';"; 
		ResultSet rs =db.getStatement().executeQuery(selstmt);
		if(rs.next()){
			return rs.getInt(1);
		}
		return null;

	}

	/**
	 * Helper method to generate specific instances of a clone.
	 * @param size - the size of the clone relative to the biosample
	 * @param sampleName - the name of the biosample
	 * @param which - the perspective from which this clone is viewed or NULL, if we have the privilege of dealing with the clone's identity
	 * @return
	 * @throws SQLException 
	 */
	public static <T extends Profile> Clone getInstance(float size,  String sampleName, Perspectives which, String[] nMut) throws SQLException{
		if(which.equals(Perspectives.Identity)){
			return new Identity(size, sampleName,nMut);
		}else if(which.equals(Perspectives.GenomePerspective)){
			GenomePerspective gP = new GenomePerspective(size, sampleName, nMut);
			return(gP);
		}else if(which.equals(Perspectives.TranscriptomePerspective)){
			TranscriptomePerspective gP = new TranscriptomePerspective(size, sampleName, nMut);
			return(gP);
		}else if(which.equals(Perspectives.KaryotypePerspective)){
			KaryotypePerspective gP = new KaryotypePerspective(size, sampleName, nMut);
			return(gP);
		}else if(which.equals(Perspectives.ExomePerspective)){
			ExomePerspective gP = new ExomePerspective(size, sampleName, nMut);
			return(gP);
		}else if(which.equals(Perspectives.MorphologyPerspective)){
			MorphologyPerspective gP = new MorphologyPerspective(size, sampleName, nMut);
			return(gP);
		}
		return null;
	}

	public int getID() {
		return cloneID;
	}

	public void setProfile(Profile p) {
		this.profile=p;
	}

	public Float getSize() {
		return size;
	}

	public void setParent(Clone clone) {
		if(!sampleSource.equals(clone.sampleSource)){
			throw new IllegalArgumentException();
		}
		this.parent=clone;
	}

	public Clone getParent() {
		return parent;
	}

	@Override
	public String toString(){
		return CloneColumnPrefix.getValue(this.getClass().getSimpleName())+"_"+size+"_ID"+cloneID;
	}

	protected Clone getChild(float size){
		for(Clone c: children){
			if (c.size==size){
				return(c);
			}
		}
		return null;
	}

	public float[] getChildrensSizes(){
		float[] s =new float[children.size()];
		for(int i =0; i<s.length; i++){
			s[i]=children.get(i).size;
		}
		return(s);
	}

	public void setID(int cloneID2) {
		this.cloneID=cloneID2;

	}

	public void setChildrenIDs(int[] childrenIDs) {
		this.childrenIDs=childrenIDs;
	}

	public String getSampleSource() {
		return sampleSource;
	}

	public int[] getChildrenIDs() {
		return this.childrenIDs;
	}

	public double[] getCoordinates() {
		return coordinates;
	}


	public void setCoordinates(double x,double y) throws Exception {
		this.coordinates = new double[]{x,y};
		
		for(Clone c : children){
			c.setCoordinates(x, y);
		}
	}

	public int countRedundant(){
		int cnt=0;
		if(this.redundant){
			cnt=1;
		}
		for(Clone c: children){
			cnt=cnt+c.countRedundant();
		}
		return(cnt);		
	}

	public abstract Clone getPerspective(Perspectives whichP);
}

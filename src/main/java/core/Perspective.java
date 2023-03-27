package core;



import java.io.File;
import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Map;

import core.utils.Helper;
import core.utils.Perspectives;
import database.CLONEID;
import database.SerializeProfile_MySQL;


/**
 * A Perspective is a complex approximate measure of a clone, striving for proximity to the clone's Identity.
 * @author noemi
 *
 */
public abstract class Perspective extends Clone {

	/**
	 * The name of the biosample in which this clone was detected.
	 */
	protected String origin;
	
	public Perspective(float f,  String sampleName) throws SQLException {
		super(f, sampleName);
	}

	public Perspective(File outFile,Perspectives whichPerspective,String rootName) throws Exception {
		super(outFile,whichPerspective, rootName);
	}


	
	protected Map<String, String> getDBformattedAttributesAsMap(){
		Map<String, String> map=super.getDBformattedAttributesAsMap();
		map.put("whichPerspective","\'"+this.getClass().getSimpleName()+"\'");
		map.put("origin","\'"+this.origin+"\'");
		return(map);
	}

	/**
	 * Adds clone @child contained within this clone to this clone's children. This method also sets the parent of @child to reference this clone.  
	 * @param c - the clone contained within this clone. 
	 */
	@Override
	protected void addChild(Clone c){
		//children and parent must be of the same type: e.g. an identity's parent can't be a perspective
		if(!c.getClass().equals(this.getClass())){
			throw new IncompatibleClassChangeError();
		}
		if(!((Perspective)c).origin.equals(origin)){
			throw new IllegalArgumentException();
		}
//		//child can't be larger than parent
//		if(c.size>=this.size){
//			throw new IllegalArgumentException("Child clone has to be smaller than parent!");
//		}
		c.parent=this; //Counting on call-by-reference effect here to ensure every child has this clone as parent
		children.add(c);
	}

	
	@Override
	public void setParent(Clone clone) {
		if(!origin.equals(((Perspective)clone).origin)){
			throw new IllegalArgumentException();
		}
		this.parent=clone;
	}
	
	/**
	 * Check if clone exists yet in DB. If so, return the clone's ID
	 */
	@Override
	protected Integer isInDB(String tableName, CLONEID db) throws Exception {
		int hash = Arrays.deepHashCode(profile.getValues());
		//@TODO: risk that clone is falsely classified as already existent even though it is not <=> hash is non-unique for long arrays
		String selstmt="SELECT cloneID from "+tableName+" where abs(size-"+this.size+")<"+Clone.PRECISION+" and profile_hash="+hash+" AND whichPerspective=\'"+this.getClass().getSimpleName()+"\' AND origin=\'"+origin+"\';"; 
		ResultSet rs =db.getStatement().executeQuery(selstmt);
		if(rs.next()){
			return rs.getInt(1);
		}
		return null;

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
	@Override
	protected void loadFromDB() throws Exception {
		CLONEID db= new CLONEID();
		db.connect();
		//@TODO: there's a risk here of overlapping clone sizes and wrong assignment of clone members
		String selstmt="SELECT cloneID,coordinates from "+CLONEID.getTableNameForClass(this.getClass().getSimpleName())+" where abs(size-"+size+")<"+PRECISION+" AND whichPerspective=\'"+this.getClass().getSimpleName()+"\' AND origin=\'"+origin+"\';";
		ResultSet rs =db.getStatement().executeQuery(selstmt);
		rs.next();
		super.cloneID=rs.getInt("cloneID");
		try{
			super.coordinates=Helper.string2double(rs.getString("coordinates").split(","));
		}catch (NullPointerException e){
			//			No coordinates available for this clone
		}
		SerializeProfile_MySQL serp=new SerializeProfile_MySQL(cloneID,this.getClass().getSimpleName());
		this.profile=serp.readProfileFromDB(db.getConnection());
		//		this.children=rs.getString("children"); //@TODO: do children need to be loaded?
		//		this.parent=Clone.getInstance(size, selstmt, which, nMut); //@TODO: does parent need to be loaded?

		db.close();

	}

}

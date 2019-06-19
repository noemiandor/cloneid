package database;


import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;

import core.Clone;
import core.Identity;
import core.Perspective;
import core.utils.Helper;
import core.utils.Perspectives;
import core.utils.Profile;

/**
 * Interface to the MySQL database CLONEID. Static class, providing methods to access and manipulate the database.
 * @author noemi
 *
 */
public final class CLONEID {
	private Connection con;

	private Statement stmt;



	public boolean connect() throws SQLException,
	InstantiationException, IllegalAccessException,
	ClassNotFoundException {
		Class.forName("com.mysql.jdbc.Driver").newInstance();
		String db_password = "lalalala";
		String db_userid = System.getProperty("user.name");

		String db_connect_string = "jdbc:mysql://cloneredesign.cswgogbb5ufg.us-east-1.rds.amazonaws.com";
		con = DriverManager.getConnection(db_connect_string, db_userid,
				db_password);
		stmt = con.createStatement();
		stmt.executeQuery("USE CLONEID");
		return true;
	}



	public void close() throws SQLException {
		con.close();
	}




	public void executeUpdate(String addstmt) throws SQLException {
		stmt.executeUpdate(addstmt);

	}



	public Connection getConnection() {
		return con;
	}



	public Statement getStatement() {
		return stmt;
	}



	public static String getTableNameForClass(String cloneClass) {
		String tableName = "Identity";
		if(!cloneClass.contains(tableName)){
			tableName="Perspective"; //@TODO: improve table choice
		}
		return(tableName);
	}

	/**
	 * Reads characteristics of a specific clone from the database, including: 
	 * - the clone's size
	 * - its parent
	 * - the IDs of its children (but not children objects themselves)
	 * - its coordinates
	 * - its profile
	 * - the IDs of its perspectives (for Identity only)
	 * 
	 * Clone is selected from the dataset based on its ID and the Perspective or Identity it represents.
	 * @param cloneID - unique ID of the clone
	 * @param which - what perspective of the clone we want to retrieve 
	 * @return
	 * @throws Exception
	 */
	public Clone getClone(int cloneID, Perspectives which) throws Exception {
		String attr="size,sampleName,whichPerspective,parent,coordinates";
		if(which==Perspectives.Identity){
			attr+=","+Arrays.toString(Perspectives.values()).replace(", Identity", "").replace("[", "").replace("]", "");

		}		
		SerializeProfile_MySQL serp=new SerializeProfile_MySQL(cloneID,which.name());
		Profile p=serp.readProfileFromDB(con);
		String selstmt="SELECT "+attr+" from "+CLONEID.getTableNameForClass(which.name())+" where cloneID="+cloneID+";";
		ResultSet rs =stmt.executeQuery(selstmt);
		rs.next();
		Clone clone=Clone.getInstance(rs.getFloat(1), rs.getString(2), which, p.getLoci());
		int parentID=rs.getInt("parent");
		String tmp=rs.getString("coordinates");
		if(tmp!=null){
			double[] coord=Helper.string2double(tmp.split(","));
			clone.setCoordinates(coord[0],coord[1]);
		}

		clone.setProfile(p);
		clone.setID(cloneID);
		//Add perspectives if this is an Identity
		Map<Perspectives, Integer> pmap=new HashMap<Perspectives, Integer>();
		if(which==Perspectives.Identity){
			for(Perspectives persp : Perspectives.values()){
				if(Perspectives.Identity!=persp){
					int pID=rs.getInt(persp.name());
					if(pID>0){
						pmap.put(persp, pID);
					}
				}
			}

		}
		clone.setChildrenIDs(getChildrenForParent(cloneID, which)); //Will open another result set and close this one -- must call last
		//Call recursively
		if(parentID>0){
			clone.setParent(getClone(parentID, which));
		}
		for(Entry<Perspectives, Integer> e :pmap.entrySet()){
			((Identity)clone).addPerspective((Perspective)getClone(e.getValue(), e.getKey()));
		}
		return(clone);
	}


	public int[] getChildrenForParent(int cloneID, Perspectives which) throws SQLException{
		String selstmt0="SELECT count(*) from "+CLONEID.getTableNameForClass(which.name())+" where parent="+cloneID+";";
		ResultSet rs0 =stmt.executeQuery(selstmt0);
		rs0.next();
		int n = rs0.getInt("count(*)");

		if(n>0){
			int[] childrenIDs= new int[n];
			String selstmt2="SELECT cloneID from "+CLONEID.getTableNameForClass(which.name())+" where parent="+cloneID+";";
			ResultSet rs2 =stmt.executeQuery(selstmt2);
			for(int i = 0; i<n; i++){
				rs2.next();
				childrenIDs[i]=Integer.parseInt(rs2.getString("cloneID"))	;
			}
			return(childrenIDs);
		}		else{
			return(null);
		}
	}

	public void update(Clone child, String fieldname, String fieldvalue) throws SQLException {
		String updateSTmt = "UPDATE " + getTableNameForClass(child.getClass().getSimpleName())+ " SET "+fieldname+"=" 
				+ fieldvalue+ " WHERE cloneID=" + child.getID();
		stmt.executeUpdate(updateSTmt);
	}




}

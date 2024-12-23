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
import services.YamlReaderService;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;


/**
 * Interface to the MySQL database CLONEID. Static class, providing methods to access and manipulate the database.
 * @author noemi
 *
 */
public final class CLONEID {

	static public Integer connection_count = 0;
  	static public Connection conx = null;
	static public Statement stmt = null;
	static public YamlReaderService yconfig = null;
  	private Connection con = null;
	// private Statement stmt = null;
	private YamlReaderService yamlReader;

	Map<Integer, Clone> cmap = new HashMap<Integer, Clone>();

	public CLONEID() {
	}

	public boolean connect() throws SQLException {

		if (CLONEID.conx == null || CLONEID.stmt == null) {
			if (CLONEID.yconfig == null) {
				yamlReader = new YamlReaderService();
				CLONEID.yconfig  = yamlReader;
			}
			String db_password = CLONEID.yconfig.getConfig().getMysqlConnection().get("password");
			String db_userid = CLONEID.yconfig.getConfig().getMysqlConnection().get("user");
					
			String db_connect_string = "jdbc:mysql://"
					+ CLONEID.yconfig.getConfig().getMysqlConnection().get("host") + ":"
					+ CLONEID.yconfig.getConfig().getMysqlConnection().get("port")
					+ "/CLONEID?enabledTLSProtocols=TLSv1.2";

			CLONEID.conx  = DriverManager.getConnection(db_connect_string, db_userid, db_password);
			con = CLONEID.conx;
			CLONEID.stmt  = con.createStatement();
		}

		con = CLONEID.conx;
		stmt =  con.createStatement();
		return true;
	}

	public void close() throws SQLException {
		return;
		//CLONEID.conx.close();
		//CLONEID.conx = null;
		// con.close();
	}

	public void executeUpdate(String addstmt) throws SQLException {
		stmt.executeUpdate(addstmt);
	}

	public Connection getConnection() {
		return CLONEID.conx;
	}

	public Statement getStatement() {
		return CLONEID.stmt;
	}

	public static String getTableNameForClass(String cloneClass) {

		return Perspectives.valueOf(cloneClass).getTableName();
		 
		// ////@TODO: remove after solving speed issues for table Perspective
		// //if(cloneClass.contains("MorphologyPerspective")){
		// //	tableName="MorphologyPerspective"; 
		// //}
		// return(tableName);
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

		Clone clone = cmap.get(cloneID);
		if (clone != null) { return clone; }

		String attr="size,origin,whichPerspective,parent,coordinates";
		if(which==Perspectives.Identity){
			attr+=","+Arrays.toString(Perspectives.values()).replace(", Identity", "").replace("[", "").replace("]", "");

		}		
		SerializeProfile_MySQL serp = new SerializeProfile_MySQL(cloneID,which.name());
		Profile p=serp.readProfileFromDB(getConnection());
		String selstmt="SELECT "+attr+" from "+which.getTableName()+" where cloneID="+cloneID+";";
		ResultSet rs =stmt.executeQuery(selstmt);
		rs.next();
		clone=Clone.getInstance(rs.getFloat(1), rs.getString(2), which, p.getLoci());
		int parentID=rs.getInt("parent");
		String tmp=rs.getString("coordinates");
		if(tmp!=null){
			double[] coord=Helper.string2double(tmp.split(","));
			clone.setCoordinates(coord[0],coord[1]);
		}

		clone.setProfile(p);
		clone.setID(cloneID);
		//Add perspectives if this is an Identity
		Map<Integer, Perspectives> pmap=new HashMap<Integer, Perspectives>();
		if (which == Perspectives.Identity) {
			Perspectives[] Perspectives_less_Identity = {
								Perspectives.GenomePerspective,
								Perspectives.ExomePerspective,
								Perspectives.TranscriptomePerspective,
								Perspectives.KaryotypePerspective,
								Perspectives.MorphologyPerspective
								};
			for (Perspectives persp : Perspectives_less_Identity ) {
				String pIDs = rs.getString(persp.name());
				if (pIDs != null) {
					for (String pID : pIDs.split(",")) {
						pmap.put(Integer.parseInt(pID), persp);
					}
				}
			}
		}
		clone.setChildrenIDs(getChildrenForParent(cloneID, which)); //Will open another result set and close this one -- must call last
		//Call recursively
		if(parentID>0){
			clone.setParent(getClone(parentID, which));
		}
		for(Entry<Integer, Perspectives> e :pmap.entrySet()){
			((Identity)clone).addPerspective((Perspective)getClone(e.getKey(), e.getValue()));
		}
		cmap.put(cloneID, clone);
		return(clone);
	}
	
	private int getResultSetRowCount(ResultSet resultSet) {
		int totalRows = 0;
		try {
			if(!resultSet.isBeforeFirst()){
				return totalRows ;    
			}
			resultSet.last();
			totalRows = resultSet.getRow();
			resultSet.beforeFirst();
		} 
		catch(Exception ex)  {
			return 0;
		}
		return totalRows ;    
	}

	public int[] getChildrenForParent(int cloneID, Perspectives which) throws SQLException{
        String selstmt = "SELECT cloneID FROM " + which.getTableName() + " WHERE parent=" + cloneID + ";";
		ResultSet rs = stmt.executeQuery(selstmt);

		int rowcount = getResultSetRowCount(rs);
        if (rowcount == 0) {
            return null;
        }
        int[] children = new int[rowcount];
        for (int i = 0; rs.next(); i++) {
            children[i] = rs.getInt("cloneID");
        }
		return children;

	}

	public void update(Clone child, String fieldname, String fieldvalue) throws SQLException {
		String updateSTmt = "UPDATE " +
							getTableNameForClass(child.getClass().getSimpleName()) +
							" SET " + fieldname +
							"=" + fieldvalue + 
							" WHERE cloneID=" + 
							child.getID();
		stmt.executeUpdate(updateSTmt);
	}

}

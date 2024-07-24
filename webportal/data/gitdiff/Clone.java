public class Clone {
     import java.io.File;
     import java.nio.charset.Charset;
     import java.nio.file.Files;
     import java.nio.file.Paths;
    import java.sql.Date;
     import java.sql.PreparedStatement;
     import java.sql.ResultSet;
     import java.sql.SQLException;
     import java.sql.Statement;
    import java.text.DateFormat;
    import java.text.SimpleDateFormat;
     import java.util.ArrayList;
     import java.util.Arrays;
     import java.util.HashMap;
     
   	public void backend_message(long txid, String Level, String k, String v) {
   		DateFormat dbTimeFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
   		String tx2 = dbTimeFormat.format(new Date(0L));
   
   		String[] levels = { "ABRT", "AFIQ", "AFIR", "DONE", "INFO", "JSON", "MESG", "MSQL", "NTIF", "PRNT", "QUIT", "RSLT", "VARS", "WRNG" };
   		boolean levelMatched = Arrays.asList(levels).contains(Level);
   
   		if (levelMatched) {
   			System.out.println("[" + Level + "]::" + txid + "::" + tx2 + "::" + k + "|" + v + "::" + txid);
   			try {
   				Thread.sleep(1000);
   			} catch (InterruptedException e) {
   				e.printStackTrace();
   			}
   			if ("ABRT".equals(Level)) {
   				try {
   					Thread.sleep(10000);
   				} catch (InterruptedException e) {
   					e.printStackTrace();
   				}
   				System.exit(0);
   			}
   		}
   	}
   
   
   	/**
   	 * Saves this clone along with all its children into the database. 
   	 * Importantly, this is the only method within which a clone's ID (@cloneID) can be assigned as the value of the primary key used to enter the clone into the database.
   	 * @throws Exception 
   	 * @TODO: this method must guarantee that a clone without a parent will not persist in the database
   	 * @TODO: this method must first remove from the database clones associated with the same perspective on this biosample, before entering the new clones.  
   	 */
   	public void save2DBX(long transactionId) throws Exception{
   
   		String tableName=CLONEID.getTableNameForClass(this.getClass().getSimpleName());
   		informUserX(transactionId);
   		for(Clone c: children){
   			c.save2DBX(transactionId);
   		}
   		CLONEID cloneid= new CLONEID();
   		cloneid.connect();
   
   		Integer existingid=isInDB(tableName, cloneid);
   		Map<String,String> map = this.getDBformattedAttributesAsMap();
   		if(existingid==null){
   			String addstmt = "INSERT INTO " + tableName+ "(";
   			String valstmt=" VALUES(";
   			for(Entry<String, String> kv : map.entrySet()){
   				addstmt+=""+kv.getKey()+", ";
   				valstmt+=""+kv.getValue()+", "; 
   			}
   			addstmt+="transactionId )";
   			valstmt+=""+transactionId+" )"; 
   			addstmt+=valstmt;
   			PreparedStatement prest= cloneid.getConnection().prepareStatement(addstmt, Statement.RETURN_GENERATED_KEYS);
   			prest.executeUpdate();
   			ResultSet rs = prest.getGeneratedKeys();
   			rs.next();
   			this.cloneID = rs.getInt(1);
   
   			SerializeProfile_MySQL serp=new SerializeProfile_MySQL(this.cloneID,this.getClass().getSimpleName());
   			serp.writeProfile2DB(cloneid.getConnection(), profile);
   		}else{
   			this.cloneID=existingid;
   			this.redundant=true;
   		}
   
   		if(children.size()>0){
   			for(Clone c: children){
   				String updateSTmt =
   				"UPDATE " +
   				tableName +
   				" SET parent=" + this.cloneID +
   				", rootID="+this.getRoot().cloneID +
   				" WHERE cloneID=" + c.cloneID +
   				";";
   				cloneid.getStatement().executeUpdate(updateSTmt);
   			}
   			String updateSTmt = "UPDATE " + tableName + " SET hasChildren=true WHERE cloneID=" + cloneID;
   			cloneid.getStatement().executeUpdate(updateSTmt);
   		}
   
   		cloneid.close();
   		
   		if(this.parent==null && countRedundant()>0){
   			backend_message(transactionId, "NTIF", "RDD", countRedundant()+"");
   			backend_message(transactionId, "JSON", "RDD",
   			"[ \"" + countRedundant() + "\" ]"
   			);
   		}
   
   	}
   
   	private void informUserX(long transactionId) {
   		Map<Double,Integer> spfreq=Helper.count(getChildrensSizes(),0.001);
   		if(spfreq.size()>0){
   			backend_message(transactionId, "NTIF", "CSS", "");
   			backend_message(transactionId, "JSON", "CSS", "[\"NULL\"]");
   			for(Entry<Double, Integer> e : spfreq.entrySet()){
   				backend_message(transactionId, "NTIF", "SFS", e.getValue() + "|" + String.format("%.7f", e.getKey()));
   				backend_message(transactionId, "JSON", "SFS",
   				 "[ \"" + e.getValue() + "\", \"" + String.format("%.7f", e.getKey()) + "\" ]"
   				 );
   			}
   		}
   	}
   
       private void informUser() {
           Map<Double,Integer> spfreq=Helper.count(getChildrensSizes(),0.001);
           if(spfreq.size()>0){
     
}

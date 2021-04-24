package core;



import java.io.File;
import java.io.IOException;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;

import core.utils.Perspectives;
import database.CLONEID;


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

	

}

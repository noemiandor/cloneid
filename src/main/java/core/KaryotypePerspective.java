package core;

import java.io.File;
import java.sql.SQLException;

import core.utils.Genome;
import core.utils.Perspectives;

/**
 * The genomic perspective on a clone.
 * @author noemi
 *
 */
public class KaryotypePerspective extends Perspective{

	public KaryotypePerspective(float f, String sampleName, String[] nMut) throws SQLException {
		super(f, sampleName);
		this.profile=new Genome(nMut);
	}
	
	public KaryotypePerspective(File outFile,String rootName) throws Exception {
		super(outFile,Perspectives.KaryotypePerspective, rootName);
	}

	@Override
	public Clone getPerspective(Perspectives whichP) {
		if(whichP.equals(Perspectives.valueOf(this.getClass().getSimpleName()))){
			return this;
		}
		return null;
	}


}

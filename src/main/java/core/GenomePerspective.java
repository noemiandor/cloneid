package core;

import java.io.File;
import java.io.IOException;
import java.sql.SQLException;

import core.utils.Genome;
import core.utils.Perspectives;

/**
 * The genomic perspective on a clone.
 * @author noemi
 *
 */
public class GenomePerspective extends Perspective{

	public GenomePerspective(float f, String sampleName, String[] nMut) throws SQLException {
		super(f, sampleName);
		this.profile=new Genome(nMut);
	}
	
	public GenomePerspective(File outFile,String rootName) throws Exception {
		super(outFile,Perspectives.GenomePerspective, rootName);
	}

	@Override
	public Clone getPerspective(Perspectives whichP) {
		if(whichP.equals(Perspectives.valueOf(this.getClass().getSimpleName()))){
			return this;
		}
		return null;
	}


}

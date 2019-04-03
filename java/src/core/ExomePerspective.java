package core;

import java.io.File;

import core.utils.Genome;
import core.utils.Perspectives;

/**
 * The genomic perspective on a clone.
 * @author noemi
 *
 */
public class ExomePerspective extends Perspective{


	public ExomePerspective(float f, String sampleName, String[] nMut) {
		super(f, sampleName);
		this.profile=new Genome(nMut);
	}

	public ExomePerspective(File outFile,String rootName) throws Exception {
		super(outFile,Perspectives.ExomePerspective, rootName);
	}

	@Override
	public Clone getPerspective(Perspectives whichP) {
		if(whichP.equals(Perspectives.valueOf(this.getClass().getSimpleName()))){
			return this;
		}
		return null;
	}




}

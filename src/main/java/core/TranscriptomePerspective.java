
package core;

import java.io.File;
import java.io.IOException;

import core.utils.Genome;
import core.utils.Perspectives;
import core.utils.Transcriptome;

/**
 * The tarnscriptome perspective on a clone.
 * @author noemi
 *
 */
public class TranscriptomePerspective extends Perspective{

	public TranscriptomePerspective(float f, String sampleName, String[] nMut) {
		super(f, sampleName);
		this.profile=new Transcriptome(nMut);
	}

	public TranscriptomePerspective(File outFile, String rootName) throws Exception {
		super(outFile,Perspectives.TranscriptomePerspective,rootName);
	}

	@Override
	public Clone getPerspective(Perspectives whichP) {
		if(whichP.equals(Perspectives.valueOf(this.getClass().getSimpleName()))){
			return this;
		}
		return null;
	}

}

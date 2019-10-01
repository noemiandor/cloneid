package useri.utils;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

import core.utils.Helper;
import core.utils.Perspectives;

/**
 * Prefix of columns within an *sps.cbs files, that represent individual clones.
 * @author noemi
 *
 */
public final class CloneColumnPrefix {
	private final static String[] VALUES=new String[] {"SP", "SP", "SP", "Clone","Clone"};
	private final static Perspectives[] KEYS=new Perspectives[]{Perspectives.ExomePerspective,Perspectives.GenomePerspective,Perspectives.KaryotypePerspective,Perspectives.TranscriptomePerspective,Perspectives.Identity};
	
	public static String getValue(Perspectives which) {
		return(VALUES[Helper.firstIndexOf(which, KEYS)]);
	}

	public static String[] values() {
		Set<String> temp = new HashSet<String>(Arrays.asList(VALUES));
		String[] uq = temp.toArray(new String[temp.size()]);
		return(uq);
	}
	
	
	
	
}

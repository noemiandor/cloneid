package useri.utils;

import core.utils.Perspectives;
import java.util.HashMap;
import java.util.Map;


/**
 * Prefix of columns within an *sps.cbs files, that represent individual clones.
 * @author noemi
 *
 */
public final class CloneColumnPrefix {

	private final static Map<Perspectives, String> keyValueMap1 = new HashMap<>();

	static {
		CloneColumnPrefix.keyValueMap1.put(Perspectives.ExomePerspective, "SP");
		CloneColumnPrefix.keyValueMap1.put(Perspectives.GenomePerspective, "SP");
		CloneColumnPrefix.keyValueMap1.put(Perspectives.KaryotypePerspective, "SP");
		CloneColumnPrefix.keyValueMap1.put(Perspectives.TranscriptomePerspective, "Clone");
		CloneColumnPrefix.keyValueMap1.put(Perspectives.MorphologyPerspective, "SP");
		CloneColumnPrefix.keyValueMap1.put(Perspectives.Identity, "Clone");
	}

	private final static Map<String, String> keyValueMap2 = new HashMap<>();

	static {
		CloneColumnPrefix.keyValueMap2.put("ExomePerspective", "SP");
		CloneColumnPrefix.keyValueMap2.put("GenomePerspective", "SP");
		CloneColumnPrefix.keyValueMap2.put("KaryotypePerspective", "SP");
		CloneColumnPrefix.keyValueMap2.put("TranscriptomePerspective", "Clone");
		CloneColumnPrefix.keyValueMap2.put("MorphologyPerspective", "SP");
		CloneColumnPrefix.keyValueMap2.put("Identity", "Clone");
	}

	public static String getValue(Perspectives which) {
		String v = CloneColumnPrefix.keyValueMap1.get(which); // No need for Helper.firstIndexOf
		return v;
	}

	public static String[] values() {
                // Set<String> temp = new HashSet<String>(Arrays.asList(VALUES));
                // String[] uq = temp.toArray(new String[temp.size()]);
                String[] uq = CloneColumnPrefix.keyValueMap1.values().toArray(new String[0]);
                return(uq);
        }

	public static String getValue(String name) {
		String v = CloneColumnPrefix.keyValueMap2.get(name); // No need for Helper.firstIndexOf
		return v;
	}



}

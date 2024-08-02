package core.utils;

/**
 * Enumeration of all potential available perspectives on a clone.
 * MySQL database contains a table named after this class, holding its instances.
 * @author noemi
 *
 */
public enum Perspectives {
	ExomePerspective,
	GenomePerspective,
	TranscriptomePerspective,
	KaryotypePerspective,
	MorphologyPerspective,
	Identity;

	public String getTableName() {

		switch(this) {
		case ExomePerspective:
			return "Perspective";

		case GenomePerspective:
			return "Perspective";

		case TranscriptomePerspective:
			return "Perspective";

		case KaryotypePerspective:
			return "Perspective";

		case MorphologyPerspective:
			return "Perspective";

		case Identity:
			return "Identity";

		default:
			return null;
		}
	}

// 	//	@TODO: ensure these names the same as the subtypes of class Perspective
// 	//@TODO: enumeration name isn't intuitive for Identity content
}

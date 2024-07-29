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


/**
 * Represents different perspectives in the CloneID system.
 * Each perspective is mapped to a database table name.
 */
// public enum Perspectives {
//     ExomePerspective("Perspective", "Exome Perspective"),
//     GenomePerspective("Perspective", "Genome Perspective"),
//     TranscriptomePerspective("Perspective", "Transcriptome Perspective"),
//     KaryotypePerspective("Perspective", "Karyotype Perspective"),
//     MorphologyPerspective("Perspective", "Morphology Perspective"),
//     Identity("Identity", "Identity");

//     private final String tableName;
//     private final String displayName;

//     Perspectives(String tableName, String displayName) {
//         this.tableName = tableName;
//         this.displayName = displayName;
//     }

//     /**
//      * Gets the database table name associated with the perspective.
//      *
//      * @return the database table name
//      */
//     public String getTableName() {
//         return tableName;
//     }

//     /**
//      * Gets the display name of the perspective.
//      *
//      * @return the display name of the perspective
//      */
//     public String getDisplayName() {
//         return displayName;
//     }

//     // public String Name() {
//     //     return name;
//     // }

// }

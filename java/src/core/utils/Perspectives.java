package core.utils;

/**
 * Enumeration of all potential available perspectives on a clone.
 * MySQL database contains a table named after this class, holding its instances.
 * @author noemi
 *
 */
public enum Perspectives {
	GenomePerspective, TranscriptomePerspective, KaryotypePerspective, Identity
	//	@TODO: ensure these names the same as the subtypes of class Perspective
	//@TODO: enumeration name isn't intuitive for Identity content
}

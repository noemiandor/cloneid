package core.utils;

import java.io.Serializable;

/**
 * Holds a one-dimensional profile, linking genomic loci to their corresponding measurements.
 * Specification of the type of genomic loci is variable - examples include: genomic coordinates, gene names.
 * Type of measurement is also variable - examples include: copy numbers, point mutations, expression levels.
 * @author noemi
 *
 */
public class Profile implements Serializable {

	/**
	 *
	 */
	private static final long serialVersionUID = 1L;
	private Double[] values;
	private String[] loci;

	public Profile(String[] loci) {
		this.values=new Double[loci.length];
		this.loci=loci;
//		this.values=Common.getBlockMatrix(0, nMut, 1);
	}

	public void modify(int rowI, double val) {
		values[rowI]=val;
//		values.setEntry(rowI, 0, val);
	}
	public void setValues(Double[] val) {
		this.values=val;
	}
	public Double[] getValues() {
		return values;
	}

	public double[] simpleValues() {
		return Helper.toDouble(values);
	}

	public int size() {
		return values.length;
	}

	public String[] getLoci() {
		return loci;
	}

	public String getLocus(int i) {
		return loci[i];
	}

}

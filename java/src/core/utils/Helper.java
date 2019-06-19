package core.utils;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


public final class Helper {
	public static final String FILE_SEPARATOR = System
			.getProperty("file.separator");
	public static final String LINE_SEPARATOR = System
			.getProperty("line.separator");
	public static final String TAB = "\t";
	public static final String NEWLINE = "\n";




	public static int firstIndexOf(Object o, Object[] array) {
		for (int i = 0; i < array.length; i++) {
			if (array[i].equals(o)) {
				return i;
			}
		}
		return -1;
	}


	public static String replaceLast(String s, String p, String new_p){
		s=s.substring(0, s.lastIndexOf(p))+s.substring(s.lastIndexOf(p), s.length()).replace(p, new_p);
		return(s);
	}

	public static BufferedReader getReader(String cbsin)
			throws FileNotFoundException {
		BufferedReader r = new BufferedReader(new FileReader(new File(cbsin)));

		int c = 0;
		try {
			// Count how many lines start with #
			String h = r.readLine();
			while (h != null && h.startsWith("#")) {
				h = r.readLine();
				c++;
			}
			// Set reader to first line that does not start with #
			r = new BufferedReader(new FileReader(new File(cbsin)));
			while (c > 0) {
				r.readLine();
				c--;
			}
		} catch (IOException e) {
			e.printStackTrace();
		}

		return r;
	}



	public static boolean isDouble(String string) {
		try {
			Double.valueOf(string);
			return true;
		} catch (NumberFormatException e) {
			return false;
		}
	}


	public static double[] fillArray(int length, double numberVal) {
		double[] a = new double[length];
		for (int i = 0; i < a.length; i++) {
			a[i] = numberVal;
		}
		return a;
	}

	public static double[] fillArray(int startNo, int stopNo) {
		double[] a = new double[stopNo - startNo];
		for (int i = startNo; i < stopNo; i++) {
			a[i - startNo] = i;
		}
		return a;
	}

	public static byte[] double2byte(Double[] values) throws IOException {
		ByteArrayOutputStream bout = new ByteArrayOutputStream();
		DataOutputStream dout = new DataOutputStream(bout);

		for (Double d : values) {
			dout.writeDouble(d);
		}
		dout.close();
		byte[] asBytes = bout.toByteArray();
		return(asBytes);

	}

	public static byte[] string2byte(String[] values) throws IOException {
		ByteArrayOutputStream bout = new ByteArrayOutputStream();
		DataOutputStream dout = new DataOutputStream(bout);

		for (String d : values) {
			dout.writeChars(d);
			dout.writeChars(NEWLINE);
		}
		dout.close();
		byte[] asBytes = bout.toByteArray();
		return(asBytes);

	}

	public static Double[] byte2double(byte[] asBytes) throws IOException {
		List<Double> dubs = new ArrayList<Double>();
		ByteArrayInputStream bin = new ByteArrayInputStream(asBytes);
		DataInputStream din = new DataInputStream(bin);
		while(din.available()>0){
			dubs.add(din.readDouble());
		}
		Double[] object = dubs.toArray(new Double[dubs.size()]);;
		return(object);
	}

	public static double parseDouble(String string) {
		if(Helper.isDouble(string)){				
			return(Double.parseDouble(string));
		}else{
			return( Double.NaN);
		}
	}

	public static double[] toDouble(Double[] rs) {
		double[] d = new double[rs.length];
		int pos = 0;
		for (Double s : rs) {
			d[pos] = s;
			pos++;
		}
		return d;
	}

	/**
	 * Histogram
	 * @param childrensSizes
	 * @param precision 
	 * @return
	 */
	public static Map<Double, Integer> count(float[] childrensSizes, double precision) {
		Map<Double,Integer> spfreq =new HashMap<Double, Integer>();
		for(double d_ : childrensSizes){
			double d=Math.round(d_/precision)*precision;
			if(spfreq.containsKey(d)){
				spfreq.put(d, spfreq.get(d)+1);
			}else{
				spfreq.put(d, 1);
			}
		}
		return spfreq;
	}

	public static String[][] sapply(List<String> lines, String fun,
			String arg) {
		String[][] out=new String[lines.size()][];
		for(int i =0; i<lines.size(); i++){
			if(fun.equals("split")){
				out[i]=lines.get(i).split(arg);
			}
		}
		return out;
	}

	public static String[] apply(String[][] lines, String fun,
			int arg) {
		String[] out=new String[lines.length];
		for(int i =0; i<lines.length; i++){
			if(fun.equals("get")){
				out[i]=lines[i][arg];
			}
		}
		return out;
	}

	public static String[] byte2String(byte[] bytes) throws IOException {
		List<String> dubs = new ArrayList<String>();
		ByteArrayInputStream bin = new ByteArrayInputStream(bytes);
		DataInputStream din = new DataInputStream(bin);
		while(din.available()>0){
			String l="";
			char c='\0';
			while(c!='\n'){
				l+=c;
				c=din.readChar();
			}
			dubs.add(l.trim());
		}
		String[] object = dubs.toArray(new String[dubs.size()]);;
		return(object);
	}

	public static int[] string2int(String[] split) {
		int[] o=new int[split.length];
		for(int i =0; i<split.length; i++){
			o[i]=Integer.parseInt(split[i]);
		}
		return o;
	}

	public static double[] string2double(String[] split) {
		double[] o=new double[split.length];
		for(int i =0; i<split.length; i++){
			o[i]=Double.parseDouble(split[i]);
		}
		return o;
	}


}

package core;

import java.io.File;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import core.utils.Helper;
import core.utils.Perspectives;
import core.utils.Profile;
import database.CLONEID;

/**
 * An Identity is a complex measure of a clone, striving for a perfect agreement among the different perspectives on the clone.
 * An Identity is shaped by either:
 * - two or more different perspectives on the clonal composition of the same specimen OR 
 * - the same perspective on the clonal composition of two or more different specimens 
 * Every clone within an Identity is build from the consensus across perspectives/specimens.
 * MySQL database contains a table named after this class, holding its instances.
 * @author noemi
 *
 */
public class Identity extends Clone {

	/**
	 * Maps available perspectives onto the clonal composition(s) of one or more specimens, that have been viewed from the corresponding perspective. 
	 */
	private Map<Perspectives,Set<Perspective>> perspectives;

	protected Identity(float size,  String sampleName, String[] nMut) throws SQLException {
		super(size, sampleName);
		this.profile=new Profile(nMut);
		perspectives=new HashMap<Perspectives,Set<Perspective>>();
	}

	public Identity(File outFile, String rootName, File srcPerspectives) throws Exception {
		super(outFile, Perspectives.Identity,rootName);
		perspectives=new HashMap<Perspectives,Set<Perspective>>();
		
		//What perspectives shaped this identity?
		List<String> lines = Files.readAllLines(Paths.get(srcPerspectives.getAbsolutePath()), Charset.defaultCharset()); //TODO: Alternative needed if file is too big to be read at once?
		String[] header=lines.get(0).split(Helper.TAB);
		int idI=Helper.firstIndexOf(this.getClass().getSimpleName(), header);

		//Load contributing perspectives from DB
		CLONEID db= new CLONEID();
		db.connect();
		for(int i=1; i<lines.size(); i++){
			for(int sI=0; sI<header.length; sI++){
				if(sI==idI){
					continue;
				}
				String[] features=lines.get(i).split(Helper.TAB);
				if("NA".equals(features[sI])){
					continue;
				}
				String[] cloneInfo=features[sI].split("_");
				Perspectives whichP=Perspectives.valueOf(header[sI]);
				Clone p=db.getClone(Integer.parseInt(cloneInfo[2].replace("ID", "")), whichP);
				Identity child=(Identity)this.getChild(Float.parseFloat(lines.get(i).split(Helper.TAB)[idI].split("_")[1]));
				if(!child.perspectives.containsKey(whichP)){
					child.perspectives.put(whichP, new HashSet<Perspective>());
				}
				child.perspectives.get(whichP).add((Perspective)p);
			}
		}
		db.close();

	}

	@Override
	public void save2DB() throws Exception{
		super.save2DB();
		//Associate IDs of contributing perspectives to this Identity in DB
		CLONEID db= new CLONEID();
		db.connect();
		for(Set<? extends Perspective> ps:perspectives.values()){
			String ids="";
			String fieldName=null;
			for(Perspective p:ps){
				ids=ids+p.getID()+",";
				fieldName=p.getClass().getSimpleName();
			}
			ids=Helper.replaceLast(ids,",", "");
			db.update(this, fieldName, "\'"+ids+"\'");
		}
		db.close();
	}

	@Override
	protected Map<String, String> getDBformattedAttributesAsMap(){
		Map<String, String> map=super.getDBformattedAttributesAsMap();
		map.put("whichPerspective","\'"+this.getClass().getSimpleName()+"\'");
		return(map);
	}

	public void addPerspective(Perspective clone) {
		Set<Perspective> l = new HashSet<Perspective>();
		Perspectives key=Perspectives.valueOf(clone.getClass().getSimpleName());
		if(perspectives.containsKey(key)){
			l=perspectives.get(key);
		}
		l.add(clone);
		perspectives.put(key,l);
	}

	public Perspective getPerspective(Perspectives p) {
		//@TODO: how to deal with multiple perspectives of same type?
		return(perspectives.get(p).iterator().next());
	}
	
	public Set<Perspective> getPerspectives(Perspectives p) {
		//@TODO: how to deal with multiple perspectives of same type?
		return(perspectives.get(p));
	}
}

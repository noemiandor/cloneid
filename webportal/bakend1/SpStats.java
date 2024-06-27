package capi;

//import cloneid.SHA512;
//import core.*;
import core.*;

import java.io.File;
import java.util.*;

import static capi.YamlReaderService.getYmlConf;

//import clextra.YamlReaderService.getYmlConf;
//import static cloneid.Manager.getYmlConf;


public class SpStats {
    public static Map<String, Number> spstats(
            String index,
            String timestamp,
            String userhash,
            String file,
            String destination,
            String perspective
    ) throws Exception {
        getYmlConf();
        String spstatsPath = destination + userhash + "/" + timestamp + "/";
        CLogger.log().info(String.format("%s", spstatsPath));

        String spfName0 = file + ".sps.cbs";
        String spfPath0 = spstatsPath + spfName0;
        File spfFile0 = new File(spfPath0);
        final Map<String, Number> resultMap = new LinkedHashMap<>();
        System.out.println("==== file ==== " + spfFile0);
        CLogger.log().info(String.format("%s", perspective));
        long transactionId = (new Date()).getTime();
        try {
            spstatsForPerspective(userhash, file, spfFile0, transactionId, spstatsPath, resultMap, perspective);
        } catch (java.sql.SQLException e) {
            System.out.println("==== Exce ==== " + e);
        }
        return resultMap;

    }


    private static void spstatsForPerspective(String userhash, String file, File spfFile0, long transactionId, String spstatsPath, Map<String, Number> resultMap, String perspective) throws Exception {

        Perspective p0 = getPerspective(spfFile0, "CN_Estimate", perspective);
        Map<Double, Integer> results;
        results = p0.save2DBX(transactionId);
        System.out.println("==== p ==== " + p0);

        for (var sp : p0.getChildrensSizes()) {
            String s1 = String.valueOf(sp);
            if (s1.length() > 9) {
                s1 = s1.substring(0, 8);
            }
            String n1 = String.format("%s.%s.sps.cbs", file, s1);
            File f1 = new File(spstatsPath + n1);
//            GenomePerspective p1 = new GenomePerspective(f1, "SP_" + sp);
//            Perspective p1 = new GenomePerspective(f1, "SP_" + sp);

            Perspective p1 = getPerspective(f1, "SP_" + sp, perspective);
            results = p1.save2DBX(transactionId);

            int sptotal = 0;
            for (Map.Entry<Double, Integer> kv : results.entrySet()) {
                sptotal += kv.getValue();
            }
            resultMap.put(p1.toString(), sptotal);

            System.out.println("==== transactionid ++++" + transactionId + "==== file ++++" + n1 + ":: perspective ++++" + p1 + ":: sptotal ++++" + sptotal);
        }
        removeLaterIfUncertifiedUser(2 * 60 * 1000, userhash, transactionId);
    }

    private static Perspective getPerspective(File file, String rootName, String perspective) throws Exception {
        Perspective p0 = switch (perspective) {
            case "GenomePerspective" -> new GenomePerspective(file, rootName);
            case "TranscriptomePerspective" -> new TranscriptomePerspective(file, rootName);
            case "KaryotypePerspective" -> new KaryotypePerspective(file, rootName);
            case "ExomePerspective" -> new ExomePerspective(file, rootName);
            case "MorphologyPerspective" -> new MorphologyPerspective(file, rootName);
            default -> null;
        };
        return p0;
    }


    private static boolean IsCertifiedUser(String userhash) {
//        String uncertified = "uncertifiedUsers";
        String uncertified = "anonymous";
        boolean u1 = userhash.equals(uncertified);
        String usha512 = SHA512.sha512(uncertified);
        boolean u2 = userhash.equals(usha512);
        return !(u1 || u2);
    }

    private static void removeLaterIfUncertifiedUser(long timelapse, String userhash, long transactionId) {
        if (!IsCertifiedUser(userhash)) dbRowsRemoval(timelapse, transactionId);
    }
//
//    private static void dbRowsRemoval() {
//        dbRowsRemoval(1 * 60 * 1000, (new Date()).getTime());
//    }

    private static void dbRowsRemoval(long delay, long transactionId) {
        TimerTask task = new TimerTask() {
            public void run() {
                try {
                    removeTransaction(transactionId);
//                    Manager.removeBefore(tstmp);
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
                System.out.println(Thread.currentThread().getName());
                System.out.println("Removal Task performed on: " + new Date());
            }
        };
        Timer timer = new Timer("Perspective Removal " + transactionId, false);
        Date later = new Date(System.currentTimeMillis() + delay);
        System.out.println("Removal of transaction " + transactionId + " Task will occur  on: " + later.toString());
        timer.schedule(task, delay);
    }

    public static void removeTransaction(long transactionId) throws Exception {
        String updateSTmt = "DELETE FROM Perspective where transactionId = " + transactionId + " ;";
        dbIO.update(updateSTmt);
    }
//
//    public static void removeBefore(long timestamp) throws Exception {
//        String updateSTmt = "DELETE FROM Perspective where transactionId < " + timestamp + " ;";
//        dbIO.update(updateSTmt);
//    }

    public static Map<String, Number> cleanspstats(
            long timestamp,
            long delta,
            String transaction
    ) throws Exception {
        getYmlConf();
        final Map<String, Number> resultMap = new LinkedHashMap<>();
        System.out.println("==== timestamp ==== " + timestamp);
//        Manager.removeBefore(timestamp);


        resultMap.put("timestamp", timestamp);
        return resultMap;
    }

}

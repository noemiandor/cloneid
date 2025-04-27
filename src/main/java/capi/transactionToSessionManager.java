package capi;

// public class transactionToSessionManager {
// }

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.logging.Level;
import java.util.logging.Logger;

import database.CLONEID;

public class transactionToSessionManager {
    private static final Logger LOGGER = Logger.getLogger(transactionToSessionManager.class.getName());

    private static final ConcurrentMap<Long, String> transactionSessionMap = new ConcurrentHashMap<>();
    private static final ConcurrentMap<Long, CLONEID> transactionCloneIdMap = new ConcurrentHashMap<>();

    // Method to associate a session with a transactionId
    public static void addSession(long transactionId, String session) {
        transactionSessionMap.put(transactionId, session);
    }

    // Method to retrieve a session by transactionId
    public static String getSession(long transactionId) {
        return transactionSessionMap.get(transactionId);
    }

    // Method to remove a session by transactionId
    public static void removeSession(long transactionId) {
        transactionSessionMap.remove(transactionId);
        transactionCloneIdMap.remove(transactionId);
    }

    // Method to associate a CLONEID instance with a transactionId
    public static void addCloneId(long transactionId, CLONEID cloneId) {
        transactionCloneIdMap.put(transactionId, cloneId);
    }

    // Method to retrieve a CLONEID instance by transactionId
    public static CLONEID getCloneId(long transactionId) {
        return transactionCloneIdMap.get(transactionId);
    }

    // Method to check if a transactionId exists
    public static boolean containsTransactionId(long transactionId) {
        // return transactionSessionMap.containsKey(transactionId);
        return transactionSessionMap.containsKey(transactionId) || transactionCloneIdMap.containsKey(transactionId);
    }
    
    // Method to check if a transactionId exists
    public static void logMaps() {
        if (capi.SystemServices.isDebug()) LOGGER.log(Level.INFO, "transactionSessionMap : {0}", new Object[] { transactionSessionMap });
        if (capi.SystemServices.isDebug()) LOGGER.log(Level.INFO, "transactionCloneIdMap : {0}", new Object[] { transactionCloneIdMap });
    }
    
    // Method to check if a transactionId exists
    public static void printMaps() {
        System.out.println(transactionSessionMap); 
        System.out.println(transactionCloneIdMap); 
    }

}
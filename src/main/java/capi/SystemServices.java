package capi;

// import org.jetbrains.annotations.NotNull;
// import org.springframework.stereotype.Service;

// @Service
public class SystemServices {

    // @NotNull
    public static Boolean isDebug() {
        return true || java.lang.management.ManagementFactory.
                getRuntimeMXBean().
                getInputArguments().toString().contains("jdwp");
    }

    public static Boolean inDev() {
        return System.getenv("INDEV").equalsIgnoreCase("true");
    }

    public static Boolean inProd() {
        return System.getenv("INPROD").equalsIgnoreCase("true");
    }

    public static Boolean inDocker() {
        return System.getenv("INSIDE_DOCKER").equalsIgnoreCase("true");
    }

    public static Boolean useBackendMessaging() {
        return System.getenv("BACKENDMESSAGING").equalsIgnoreCase("true");
    }
}

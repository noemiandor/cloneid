package core.utils;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.zip.Deflater;
import java.util.zip.Inflater;

public class CompressionUtils {

    // Compress a byte array using Deflater
    public static byte[] compress(byte[] data) throws IOException {
        if (data == null || data.length == 0) {
            return new byte[0];
        }

        Deflater deflater = new Deflater();
        deflater.setInput(data);
        deflater.finish();

        try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream(data.length)) {
            byte[] buffer = new byte[1024];
            while (!deflater.finished()) {
                int count = deflater.deflate(buffer);
                outputStream.write(buffer, 0, count);
            }
            return outputStream.toByteArray();
        }
    }

    // Decompress a byte array using Inflater
    public static byte[] decompress(byte[] data) throws IOException {
        if (data == null || data.length == 0) {
            return new byte[0];
        }

        Inflater inflater = new Inflater();
        inflater.setInput(data);

        try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream(data.length)) {
            byte[] buffer = new byte[1024];
            while (!inflater.finished()) {
                int count = inflater.inflate(buffer);
                outputStream.write(buffer, 0, count);
            }
            return outputStream.toByteArray();
        } catch (Exception e) {
            throw new IOException("Failed to decompress data", e);
        }
    }
}

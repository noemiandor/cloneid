package core.utils;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;

public class DoubleArraySerializer {

    public static boolean compress = false;

    public static byte[] serialize(Double[] doubleArray) throws IOException {

        if (doubleArray == null || doubleArray.length == 0) {
            return new byte[0];
        }

        ByteBuffer buffer = ByteBuffer.allocate(doubleArray.length * Double.BYTES);
        for (Double d : doubleArray) {
            buffer.putDouble(d);
        }

        byte[] byteArray = buffer.array();

        if (DoubleArraySerializer.compress) {
            byte[] compressedArray = CompressionUtils.compress(byteArray);
            // byte[] compressedArray = LZ4CompressionUtil.compress(byteArray);
           return compressedArray;
        }

        return byteArray;
    }

    public static Double[] deserialize(byte[] byteArray) throws IOException {
        if (byteArray == null || byteArray.length == 0) {
            return new Double[0];
        }

        if (DoubleArraySerializer.compress) {
            byteArray = CompressionUtils.decompress(byteArray);
            // byteArray = LZ4CompressionUtil.decompress(byteArray);
        }

        int numDoubles = byteArray.length / Double.BYTES;
        ByteBuffer buffer = ByteBuffer.wrap(byteArray);
        List<Double> doubleList = new ArrayList<>();

        for (int i = 0; i < numDoubles; i++) {
            doubleList.add(buffer.getDouble());
        }

        return doubleList.toArray(new Double[0]);
    }

}
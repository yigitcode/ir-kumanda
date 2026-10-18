package com.irkumanda.kopru;

import android.content.Context;
import android.hardware.ConsumerIrManager;
import android.os.Build;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

/**
 * Minimal LAN HTTP bridge. Serves the test panel and forwards raw IR patterns
 * (alternating on/off microseconds, starting with "on") to ConsumerIrManager.
 * All protocol encoding (NEC, RC5, Pronto) happens in the panel.
 */
final class IrServer extends Thread {
    interface Listener {
        void onLog(String line);
    }

    private static final String JSON = "application/json; charset=utf-8";
    private static final int MAX_LINE = 8192;
    private static final int MAX_BODY = 256 * 1024;
    private static final int MAX_PATTERN = 4096;
    private static final int MAX_DURATION_US = 200_000;

    private final Context context;
    private final ConsumerIrManager ir;
    private final Listener listener;
    private final ServerSocket socket;
    private final Object irLock = new Object();

    IrServer(Context context, ConsumerIrManager ir, int port, Listener listener) throws IOException {
        super("ir-http");
        this.context = context.getApplicationContext();
        this.ir = ir;
        this.listener = listener;
        socket = new ServerSocket();
        socket.setReuseAddress(true);
        socket.bind(new InetSocketAddress(port));
    }

    void shutdown() {
        interrupt();
        try {
            socket.close();
        } catch (IOException ignored) {
            // Already closed.
        }
    }

    @Override
    public void run() {
        while (!isInterrupted()) {
            try {
                Socket client = socket.accept();
                new Thread(() -> serve(client), "ir-http-client").start();
            } catch (IOException e) {
                if (socket.isClosed()) return;
                listener.onLog("bağlantı hatası: " + e.getMessage());
            }
        }
    }

    private void serve(Socket client) {
        try (Socket s = client) {
            s.setSoTimeout(10_000);
            InputStream in = s.getInputStream();
            String requestLine = readLine(in);
            if (requestLine == null) return;
            String[] parts = requestLine.split(" ");
            if (parts.length < 2) return;
            String method = parts[0];
            String path = parts[1];
            int query = path.indexOf('?');
            if (query >= 0) path = path.substring(0, query);

            Map<String, String> headers = new HashMap<>();
            String line;
            while ((line = readLine(in)) != null && !line.isEmpty()) {
                int colon = line.indexOf(':');
                if (colon > 0) {
                    headers.put(line.substring(0, colon).trim().toLowerCase(Locale.ROOT), line.substring(colon + 1).trim());
                }
            }
            int length = 0;
            String lengthHeader = headers.get("content-length");
            if (lengthHeader != null) {
                try {
                    length = Integer.parseInt(lengthHeader);
                } catch (NumberFormatException ignored) {
                    length = 0;
                }
            }
            OutputStream out = s.getOutputStream();
            if (length < 0 || length > MAX_BODY) {
                respond(out, 413, "text/plain; charset=utf-8", "istek çok büyük");
                return;
            }
            String body = new String(readExactly(in, length), StandardCharsets.UTF_8);
            route(out, method, path, body);
        } catch (Exception e) {
            listener.onLog("istek hatası: " + e);
        }
    }

    private void route(OutputStream out, String method, String path, String body) throws IOException {
        if (method.equals("OPTIONS")) {
            respond(out, 204, "text/plain", "");
        } else if (method.equals("GET") && (path.equals("/") || path.equals("/index.html"))) {
            respond(out, 200, "text/html; charset=utf-8", readAsset("panel.html"));
        } else if (method.equals("GET") && path.equals("/api/info")) {
            respond(out, 200, JSON, info());
        } else if (method.equals("POST") && path.equals("/api/transmit")) {
            transmit(out, body);
        } else {
            respond(out, 404, "text/plain; charset=utf-8", "bulunamadı");
        }
    }

    private void transmit(OutputStream out, String body) throws IOException {
        try {
            JSONObject req = new JSONObject(body);
            int freq = req.getInt("freq");
            JSONArray arr = req.getJSONArray("pattern");
            String label = req.optString("label", "?");
            if (ir == null || !ir.hasIrEmitter()) throw new IllegalStateException("telefonda IR verici yok");
            if (freq < 20_000 || freq > 60_000) throw new IllegalArgumentException("frekans 20–60 kHz dışında: " + freq);
            if (arr.length() == 0 || arr.length() > MAX_PATTERN) {
                throw new IllegalArgumentException("desen uzunluğu geçersiz: " + arr.length());
            }
            int[] pattern = new int[arr.length()];
            long totalUs = 0;
            for (int i = 0; i < pattern.length; i++) {
                int v = arr.getInt(i);
                if (v <= 0 || v > MAX_DURATION_US) throw new IllegalArgumentException("geçersiz süre [" + i + "] = " + v);
                pattern[i] = v;
                totalUs += v;
            }
            long t0 = System.nanoTime();
            synchronized (irLock) {
                ir.transmit(freq, pattern);
            }
            long ms = (System.nanoTime() - t0) / 1_000_000;
            listener.onLog(String.format(Locale.ROOT, "%s  %d Hz, %d süre, %.1f ms", label, freq, pattern.length, totalUs / 1000.0));
            respond(out, 200, JSON, "{\"ok\":true,\"ms\":" + ms + ",\"totalUs\":" + totalUs + "}");
        } catch (JSONException | IllegalArgumentException e) {
            fail(out, 400, e);
        } catch (Exception e) {
            fail(out, 500, e);
        }
    }

    private void fail(OutputStream out, int status, Exception e) throws IOException {
        String msg = e.getMessage() != null ? e.getMessage() : e.toString();
        listener.onLog("HATA: " + msg);
        respond(out, status, JSON, "{\"ok\":false,\"error\":" + JSONObject.quote(msg) + "}");
    }

    private String info() {
        boolean has = false;
        StringBuilder ranges = new StringBuilder("[");
        try {
            if (ir != null) {
                has = ir.hasIrEmitter();
                ConsumerIrManager.CarrierFrequencyRange[] list = ir.getCarrierFrequencies();
                if (list != null) {
                    for (int i = 0; i < list.length; i++) {
                        if (i > 0) ranges.append(',');
                        ranges.append('[').append(list[i].getMinFrequency()).append(',').append(list[i].getMaxFrequency()).append(']');
                    }
                }
            }
        } catch (Exception e) {
            listener.onLog("frekans listesi okunamadı: " + e.getMessage());
        }
        ranges.append(']');
        return "{\"hasIrEmitter\":" + has
                + ",\"carrierFrequencies\":" + ranges
                + ",\"manufacturer\":" + JSONObject.quote(Build.MANUFACTURER)
                + ",\"model\":" + JSONObject.quote(Build.MODEL)
                + ",\"device\":" + JSONObject.quote(Build.DEVICE)
                + ",\"android\":" + JSONObject.quote(Build.VERSION.RELEASE)
                + ",\"sdk\":" + Build.VERSION.SDK_INT + "}";
    }

    private String readAsset(String name) throws IOException {
        try (InputStream in = context.getAssets().open(name)) {
            ByteArrayOutputStream buf = new ByteArrayOutputStream();
            byte[] chunk = new byte[8192];
            int n;
            while ((n = in.read(chunk)) > 0) buf.write(chunk, 0, n);
            return new String(buf.toByteArray(), StandardCharsets.UTF_8);
        }
    }

    private static String readLine(InputStream in) throws IOException {
        ByteArrayOutputStream buf = new ByteArrayOutputStream();
        int b;
        while ((b = in.read()) != -1) {
            if (b == '\n') break;
            if (b != '\r') buf.write(b);
            if (buf.size() > MAX_LINE) throw new IOException("satır çok uzun");
        }
        if (b == -1 && buf.size() == 0) return null;
        return new String(buf.toByteArray(), StandardCharsets.UTF_8);
    }

    private static byte[] readExactly(InputStream in, int length) throws IOException {
        byte[] data = new byte[length];
        int off = 0;
        while (off < length) {
            int n = in.read(data, off, length - off);
            if (n < 0) throw new IOException("gövde eksik geldi");
            off += n;
        }
        return data;
    }

    private static void respond(OutputStream out, int status, String type, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        String head = "HTTP/1.1 " + status + " " + reason(status) + "\r\n"
                + "Content-Type: " + type + "\r\n"
                + "Content-Length: " + bytes.length + "\r\n"
                + "Access-Control-Allow-Origin: *\r\n"
                + "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n"
                + "Access-Control-Allow-Headers: Content-Type\r\n"
                + "Access-Control-Allow-Private-Network: true\r\n"
                + "Cache-Control: no-store\r\n"
                + "Connection: close\r\n\r\n";
        out.write(head.getBytes(StandardCharsets.US_ASCII));
        out.write(bytes);
        out.flush();
    }

    private static String reason(int status) {
        switch (status) {
            case 200: return "OK";
            case 204: return "No Content";
            case 400: return "Bad Request";
            case 404: return "Not Found";
            case 413: return "Payload Too Large";
            default: return "Error";
        }
    }
}

package com.irkumanda.kopru;

import android.app.Activity;
import android.graphics.Typeface;
import android.hardware.ConsumerIrManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.WindowManager;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.IOException;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.text.SimpleDateFormat;
import java.util.Collections;
import java.util.Date;
import java.util.Locale;

/** Shows the bridge address and a send log; the bridge runs while this screen is open. */
public class MainActivity extends Activity implements IrServer.Listener {
    static final int PORT = 8765;
    private static final int MAX_LOG_CHARS = 8000;

    private final Handler ui = new Handler(Looper.getMainLooper());
    private TextView log;
    private IrServer server;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        int pad = (int) (16 * getResources().getDisplayMetrics().density);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(pad, pad * 3, pad, pad);

        TextView status = new TextView(this);
        status.setTextSize(18);
        status.setTextIsSelectable(true);

        log = new TextView(this);
        log.setTypeface(Typeface.MONOSPACE);
        log.setTextSize(12);
        log.setPadding(0, pad, 0, 0);
        ScrollView scroll = new ScrollView(this);
        scroll.addView(log);

        root.addView(status);
        root.addView(scroll, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f));
        setContentView(root);

        ConsumerIrManager ir = (ConsumerIrManager) getSystemService(CONSUMER_IR_SERVICE);
        String irState = ir != null && ir.hasIrEmitter()
                ? "IR verici: VAR"
                : "IR verici: YOK (bu telefon IR gönderemez)";
        try {
            server = new IrServer(this, ir, PORT, this);
            server.start();
            status.setText(irState + "\n\nBilgisayarın tarayıcısında aç:\n" + addresses()
                    + "\n\nBu ekran açık kaldıkça çalışır.");
        } catch (IOException e) {
            status.setText(irState + "\n\nSunucu başlatılamadı: " + e.getMessage());
        }
    }

    @Override
    protected void onDestroy() {
        if (server != null) server.shutdown();
        super.onDestroy();
    }

    @Override
    public void onLog(String line) {
        String stamp = new SimpleDateFormat("HH:mm:ss", Locale.ROOT).format(new Date());
        ui.post(() -> {
            String text = stamp + "  " + line + "\n" + log.getText();
            log.setText(text.length() > MAX_LOG_CHARS ? text.substring(0, MAX_LOG_CHARS) : text);
        });
    }

    private static String addresses() {
        StringBuilder sb = new StringBuilder();
        try {
            for (NetworkInterface nif : Collections.list(NetworkInterface.getNetworkInterfaces())) {
                if (!nif.isUp() || nif.isLoopback()) continue;
                for (InetAddress a : Collections.list(nif.getInetAddresses())) {
                    if (a instanceof Inet4Address && a.isSiteLocalAddress()) {
                        sb.append("http://").append(a.getHostAddress()).append(':').append(PORT).append('\n');
                    }
                }
            }
        } catch (Exception ignored) {
            // Fall through to the "not found" hint below.
        }
        return sb.length() > 0 ? sb.toString().trim() : "(Wi-Fi adresi bulunamadı — telefon Wi-Fi'ye bağlı mı?)";
    }
}

import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

/**
 * Minimal HTTP server using only the JDK's built-in com.sun.net.httpserver.
 * No Maven, no Gradle, no external dependency - so the Dockerfile stays honest
 * about what a plain JDK image costs.
 */
public class HelloWorld {

    private static final int PORT = 8080;

    // Java text block (JDK 15+) so the HTML can keep its double quotes as-is
    private static final String PAGE = """
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Hello World from Java!</title><style>body{font-family:system-ui,-apple-system,Segoe UI,sans-serif;display:grid;place-items:center;height:100vh;margin:0;background:#0b1020;color:#e2e8f0}.card{text-align:center;padding:2rem 3rem;border:1px solid #23304d;border-radius:12px;background:#111a2e;box-shadow:0 10px 40px rgba(0,0,0,.4)}h1{margin:0 0 .75rem;font-size:1.6rem}.meta{color:#8b9bbd;font-size:.9rem;line-height:1.7}code{background:#0b1020;padding:.1rem .4rem;border-radius:4px;color:#93c5fd}</style></head><body><div class="card"><h1>Hello World from Java!</h1><div class="meta">Served by the JDK's built-in <code>HttpServer</code> on <code>eclipse-temurin:21</code><br>Container port <code>8080</code> &rarr; host port <code>8082</code><br>Utkarsh Bahuguna &middot; 10161</div></div></body></html>""";

    public static void main(String[] args) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress("0.0.0.0", PORT), 0);

        server.createContext("/", exchange -> {
            byte[] body = PAGE.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "text/html; charset=utf-8");
            exchange.sendResponseHeaders(200, body.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(body);
            }
        });

        server.setExecutor(null);
        server.start();
        System.out.println("Java server running on port " + PORT);
    }
}

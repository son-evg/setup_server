# White list
# Black list
# Link secure whitelist

backend u_1000 {
   .host = "172.18.10.40";
   .port = "8080";
   .connect_timeout = 5s;
   .first_byte_timeout = 5s;
   .between_bytes_timeout  = 5s;
}

# Round Robin
# Failover
# IP HASH

sub vcl_recv {
    if (req.http.host == "cdnlive.xxxxxxxx.live") {
        set req.backend_hint = u_1000;
        set req.http.Host = "172.17.10.40";
        unset req.http.CF-RAY;
        unset req.http.CF-Connecting-IP;
        # Secure Method
        if (req.method != "PURGE" && req.method != "GET" && req.method != "HEAD" && req.method != "OPTIONS") {
            return (synth(403, "Forbidden"));
        }
        # Secure Referer
        #if (req.http.referer !~ "^http(|s)://gogotv.live" && req.http.referer !~ "^http(|s)://facebook.com") {
        #    return (synth(403, "Forbidden"));
        #}
        # User Agent
        if (req.http.X-USER-IP) {
            set req.http.X-Client-IP = req.http.X-USER-IP;
        } else {
            set req.http.X-Client-IP = client.ip;
        }
        # Rate Limit
        # CORS
        set req.http.CORS = "http://gogotv.live";
        # GeoIP Black List
        # Black List
        # White List
        # HLS 

        # Secure Link
        # Not Secure Link
        if (req.url ~ "\.m3u8") {
            unset req.http.Cookie;
            return (hash);
        }
        if (req.url ~ "\.ts") {
            set req.url = regsub(req.url, "^(.*)\?hotkey=([a-zA-Z0-9]+)&time=([0-9]+)(.*)", "\1");
            unset req.http.Cookie;
            return (hash);
        }
        # MPEG DASH
        if (req.url ~ "\.mpd") {
            unset req.http.Cookie;
            return (pass);
        }
        if (req.url ~ "\.m4s") {
            unset req.http.Cookie;
            return (hash);
        }
        return (pass);
    }
}

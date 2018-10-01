sub vcl_pipe {
  if (req.http.upgrade) {
    set bereq.http.upgrade = req.http.upgrade;
  }
  return (pipe);
}
sub vcl_pass {
}

sub vcl_hash {
  hash_data(req.url);
  if (req.http.host) {
    hash_data(req.http.host);
  } else {
    hash_data(server.ip);
  }
  if (req.http.Cookie) {
    hash_data(req.http.Cookie);
  }
}

sub vcl_hit {
  if (obj.ttl >= 0s) {
    return (deliver);
  }
 return (fetch);
}

sub vcl_miss {
    return (fetch);
}
sub vcl_backend_response {
  if (bereq.url ~ "\.m3u8") {
    set beresp.grace = 5s;
    set beresp.ttl = 2s;
    set beresp.http.Cache-Control = "max-age=1";
  }
  if (bereq.url ~ "\.ts") {
    set beresp.grace = 1m;
    set beresp.ttl = 1m;
    set beresp.http.Cache-Control = "max-age=60";
  }
  if (bereq.url ~ "\.mpd") {
    set beresp.grace = 5s;
    set beresp.ttl = 2s;
    set beresp.http.Cache-Control = "max-age=1";
  }
  if (bereq.url ~ "\.m4s") {
    set beresp.grace = 1m;
    set beresp.ttl = 1m;
    set beresp.http.Cache-Control = "max-age=60";
  }
  if (beresp.status == 403 || beresp.status == 404 || beresp.status >= 500) {
    set beresp.ttl = 2s;
  }
  set beresp.do_stream = true;
  return (deliver);
}
sub vcl_backend_error {
  if (beresp.status == 503 || beresp.status == 502) {
    set beresp.http.Content-Type = "text/html; charset=utf-8";
    synthetic(std.fileread("/var/www/html/errors/503.html"));
      return(deliver);
   }
  if (beresp.status == 500) {
    set beresp.http.Content-Type = "text/html; charset=utf-8";
    synthetic(std.fileread("/var/www/html/errors/500.html"));
      return(deliver);
   }
  return (deliver);
}
sub vcl_deliver {
  if (obj.hits > 0) {
    set resp.http.X-Cache = "HIT";
  }
  else {
    set resp.http.X-Cache = "MISS";
  }
  if (req.http.CORS == "1") {
    set resp.http.Access-Control-Allow-Origin = "http://gogotv.live";
  }
  set resp.http.Server = "nginx";
  unset resp.http.X-Powered-By;
  unset resp.http.X-Cache-Hits;
  unset resp.http.X-Varnish;
  unset resp.http.Via;
  unset resp.http.Link;
  unset resp.http.X-Generator;
  unset resp.http.ETag;
  unset resp.http.CF-RAY;
  if (req.http.CF-IP){
    set resp.http.CF-Connecting-IP = req.http.CF-IP;
  }
  return (deliver);
}
sub vcl_purge {
  if (req.method != "PURGE") {
    set req.http.X-Purge = "Yes";
    return(restart);
  }
}

sub vcl_synth {
  unset resp.http.Server;
  unset resp.http.X-Varnish;
  if (resp.status == 403) {
    synthetic(std.fileread("/var/www/html/errors/403.html"));
    return(deliver);
  }
  if (resp.status == 429) {
    synthetic(std.fileread("/var/www/html/errors/429.html"));
    return(deliver);
  }
  if (resp.status == 477) {
    synthetic(std.fileread("/var/www/html/errors/477.html"));
    return(deliver);
  }
  if (resp.status == 700) {
    set resp.http.Content-Type = "text/html; charset=utf-8";
    set resp.status = 200;
    set resp.reason = "OK";
    synthetic("-777-");
    return(deliver);
  }
  return (deliver);
}

sub vcl_fini {
  return (ok);
}

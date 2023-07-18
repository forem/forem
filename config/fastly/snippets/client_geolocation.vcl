sub vcl_recv {
  declare local var.code STRING;

  if (client.geo.country_code != "**") {
    set var.code = client.geo.country_code;
    if (client.geo.region != "NO REGION" && client.geo.region != "?") {
      set var.code = var.code + "-" + client.geo.region;
    }
  }

  set req.http.HTTP_CLIENT_GEO = var.code;
}

sub vcl_recv {
  declare local var.code STRING;

  if (client.geo.country_code != "**") { // Indicates a reserved country block
    set var.code = client.geo.country_code;

    if (
      client.geo.region != "NO REGION" && // The country has no regions
      client.geo.region != "AOL" && // For some reason the ISP AOL uses itself as a region
      client.geo.region != "?" && // The country has regions, but it is absent/indeterminate
      client.geo.region != "***" // Indicates a reserved region block
    ) {
      set var.code = var.code + "-" + client.geo.region;
    }

    set req.http.HTTP_CLIENT_GEO = var.code;
  }
}

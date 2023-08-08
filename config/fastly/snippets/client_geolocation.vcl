sub vcl_init {
  table active_geofencing_regions {
    // This (empty) table is managed independently of the deployed configuration as an edge dictionary.
    // As implemented below, if the full ISO 3166-2 country+region code isn't present in this table,
    // then we fall back to caching at a country level.

    // This accomplishes a couple of things:
    // 1. It greatly reduces the number of variants that need to be cached
    // 2. It lets us enable more granular caching (for big campaigns and/or customers)
    //    without having to redeploy the app.
  }
}

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

    set req.http.X-Client-Geo = var.code;
    set req.http.X-Cacheable-Client-Geo = table.lookup(
      active_geofencing_regions, // Table ID
      var.code, // Key
      client.geo.country_code // Fallback if key not found
    );
  }
}

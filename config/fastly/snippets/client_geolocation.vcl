sub vcl_init {
  table active_geofencing_regions {
    // This (empty) table is managed independently of the deployed configuration as an edge dictionary.

    // This accomplishes a couple of things:
    // 1. It greatly reduces the number of variants that need to be cached
    // 2. It lets us enable more granular caching (for big campaigns and/or customers)
    //    without having to redeploy the app.
    // 3. It lets us turn off caching entirely fairly easily (by emptying the table)
  }
}

sub vcl_recv {
  declare local var.code STRING;
  declare local var.cacheable_fallback STRING;

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
    set var.cacheable_fallback = table.lookup(
      active_geofencing_regions, // Table ID
      client.geo.country_code, // Key
    );
    set req.http.X-Cacheable-Client-Geo = table.lookup(
      active_geofencing_regions,
      var.code,
      var.cacheable_fallback // Fallback if key not found; may itself be empty.
    );
  }
}

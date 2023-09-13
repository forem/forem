table active_geofencing_regions {
  // This table can be managed independently of the deployed configuration as an edge dictionary.

  // This accomplishes a couple of things:
  // 1. It greatly reduces the number of variants that need to be cached
  // 2. It lets us enable more granular caching (for big campaigns and/or customers)
  //    without having to redeploy the app.
  // 3. It lets us turn off geofenced caching entirely fairly easily (by emptying the table)
  "CA": "CA",  // Canada
  "US": "US",  // USA
  "AU": "AU",  // Australia
  "BR": "BR",  // Brazil
  "CN": "CN",  // China
  "FR": "FR",  // France
  "DE": "DE",  // Germany
  "IN": "IN",  // India
  "ID": "ID",  // Indonesia
  "MY": "MY",  // Malaysia
  "NZ": "NZ",  // New Zealand
  "PH": "PH",  // Philippines
  "RU": "RU",  // Russia
  "SG": "SG",  // Singapore
  "GB": "GB"   // United Kingdom
}

sub vcl_recv {
  declare local var.code STRING;
  declare local var.cacheable_code STRING;

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
    // Ternary "if" construct lets us fall back to trying to cache at a country level
    // if the more specific country+region code isn't currently set to be cached.
    set var.cacheable_code = if(
      table.contains(active_geofencing_regions, var.code),
      var.code,
      client.geo.country_code
    );
    // If neither country nor country+region code are in the edge dictionary, this header
    // will be empty. All locations where we don't offer targeting (yet) will thus share
    // the same cache.
    set req.http.X-Cacheable-Client-Geo = table.lookup(
      active_geofencing_regions,
      var.cacheable_code,
      ""
    );
  }
}

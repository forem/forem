task periodic_cache_bust: :environment do
  CacheBuster.bust("/feed.xml")
  CacheBuster.bust("/badge")
  CacheBuster.bust("/shecoded")
end

task hourly_bust: :environment do
  CacheBuster.bust("/")
end

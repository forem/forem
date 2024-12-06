begin
  begin
    # rack/version exists in Rack 2.2.0 and later, compatible with Ruby 2.3 and later
    # we prefer to not load Rack
    require 'rack/version'
  rescue LoadError
    require 'rack'
  end

  # Rack.release is needed for Rack v1, Rack::RELEASE was added in v2
  if Gem::Version.new(Rack.release) >= Gem::Version.new("3.0.0")
    raise StandardError.new "Puma 5 is not compatible with Rack 3, please upgrade to Puma 6 or higher."
  end
rescue LoadError
end

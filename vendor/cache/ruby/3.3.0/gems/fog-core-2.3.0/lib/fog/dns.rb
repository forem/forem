module Fog
  module DNS
    extend Fog::ServicesMixin

    def self.zones
      zones = []
      providers.each do |provider|
        begin
          zones.concat(self[provider].zones)
        rescue # ignore any missing credentials/etc
        end
      end
      zones
    end
  end
end

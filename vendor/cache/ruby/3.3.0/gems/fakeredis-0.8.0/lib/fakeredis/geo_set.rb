module FakeRedis
  class GeoSet
    class Point
      BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz" # (geohash-specific) Base32 map
      EARTH_RADIUS_IN_M = 6_378_100.0

      attr_reader :lon, :lat, :name

      def initialize(lon, lat, name)
        @lon = Float(lon)
        @lat = Float(lat)
        @name = name
      end

      def geohash(precision = 10)
        latlon = [@lat, @lon]
        ranges = [[-90.0, 90.0], [-180.0, 180.0]]
        coordinate = 1

        (0...precision).map do
          index = 0 # index into base32 map

          5.times do |bit|
            mid = (ranges[coordinate][0] + ranges[coordinate][1]) / 2
            if latlon[coordinate] >= mid
              index = index * 2 + 1
              ranges[coordinate][0] = mid
            else
              index *= 2
              ranges[coordinate][1] = mid
            end

            coordinate ^= 1
          end

          BASE32[index]
        end.join
      end

      def distance_to(other)
        lat1 = deg_to_rad(@lat)
        lon1 = deg_to_rad(@lon)
        lat2 = deg_to_rad(other.lat)
        lon2 = deg_to_rad(other.lon)
        haversine_distance(lat1, lon1, lat2, lon2)
      end

      private

      def deg_to_rad(deg)
        deg * Math::PI / 180.0
      end

      def haversine_distance(lat1, lon1, lat2, lon2)
        h = Math.sin((lat2 - lat1) / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) *
              Math.sin((lon2 - lon1) / 2) ** 2

        2 * EARTH_RADIUS_IN_M * Math.asin(Math.sqrt(h))
      end
    end

    def initialize
      @points = {}
    end

    def size
      @points.size
    end

    def add(lon, lat, name)
      @points[name] = Point.new(lon, lat, name)
    end

    def get(name)
      @points[name]
    end

    def points_within_radius(center, radius)
      @points.values.select do |point|
        point.distance_to(center) <= radius
      end
    end
  end
end

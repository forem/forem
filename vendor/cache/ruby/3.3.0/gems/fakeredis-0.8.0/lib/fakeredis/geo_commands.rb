require "fakeredis/geo_set"

module FakeRedis
  module GeoCommands
    DISTANCE_UNITS = {
      "m" => 1,
      "km" => 1000,
      "ft" => 0.3048,
      "mi" => 1609.34
    }

    REDIS_DOUBLE_PRECISION = 4
    REDIS_GEOHASH_SIZE = 10

    def geoadd(key, *members)
      raise_argument_error("geoadd") if members.empty? || members.size % 3 != 0

      set = (data[key] ||= GeoSet.new)
      prev_size = set.size
      members.each_slice(3) do |member|
        set.add(*member)
      end
      set.size - prev_size
    end

    def geodist(key, member1, member2, unit = "m")
      unit = unit.to_s
      raise_command_error("ERR unsupported unit provided. please use #{DISTANCE_UNITS.keys.join(', ')}") unless DISTANCE_UNITS.include?(unit)

      set = (data[key] || GeoSet.new)
      point1 = set.get(member1)
      point2 = set.get(member2)
      if point1 && point2
        distance = point1.distance_to(point2)
        distance_in_units = distance / DISTANCE_UNITS[unit]
        distance_in_units.round(REDIS_DOUBLE_PRECISION).to_s
      end
    end

    def geohash(key, member)
      members = Array(member)
      raise_argument_error("geohash") if members.empty?
      set = (data[key] || GeoSet.new)
      members.map do |member|
        point = set.get(member)
        point.geohash(REDIS_GEOHASH_SIZE) if point
      end
    end

    def geopos(key, member)
      return nil unless data[key]

      members = Array(member)
      set = (data[key] || GeoSet.new)
      members.map do |member|
        point = set.get(member)
        [point.lon.to_s, point.lat.to_s] if point
      end
    end

    def georadius(*args)
      args = args.dup
      raise_argument_error("georadius") if args.size < 5
      key, lon, lat, radius, unit, *rest = args
      raise_argument_error("georadius") unless DISTANCE_UNITS.has_key?(unit)
      radius *= DISTANCE_UNITS[unit]

      set = (data[key] || GeoSet.new)
      center = GeoSet::Point.new(lon, lat, nil)

      do_georadius(set, center, radius, unit, rest)
    end

    def georadiusbymember(*args)
      args = args.dup
      raise_argument_error("georadiusbymember") if args.size < 4
      key, member, radius, unit, *rest = args
      raise_argument_error("georadiusbymember") unless DISTANCE_UNITS.has_key?(unit)
      radius *= DISTANCE_UNITS[unit]

      set = (data[key] || GeoSet.new)
      center = set.get(member)
      raise_command_error("ERR could not decode requested zset member") unless center

      do_georadius(set, center, radius, unit, args)
    end

    private

    def do_georadius(set, center, radius, unit, args)
      points = set.points_within_radius(center, radius)

      options = georadius_options(args)

      if options[:asc]
        points.sort_by! { |p| p.distance_to(center) }
      elsif options[:desc]
        points.sort_by! { |p| -p.distance_to(center) }
      end

      points = points.take(options[:count]) if options[:count]
      extras = options[:extras]
      return points.map(&:name) if extras.empty?

      points.map do |point|
        member = [point.name]

        extras.each do |extra|
          case extra
          when "WITHCOORD"
            member << [point.lon.to_s, point.lat.to_s]
          when "WITHDIST"
            distance = point.distance_to(center)
            distance_in_units = distance / DISTANCE_UNITS[unit]
            member << distance_in_units.round(REDIS_DOUBLE_PRECISION).to_s
          when "WITHHASH"
            member << point.geohash(REDIS_GEOHASH_SIZE)
          end
        end

        member
      end
    end

    def georadius_options(args)
      options = {}
      args = args.map { |arg| arg.to_s.upcase }

      if idx = args.index("COUNT")
        options[:count] = Integer(args[idx + 1])
      end

      options[:asc]  = true if args.include?("ASC")
      options[:desc] = true if args.include?("DESC")

      extras = args & ["WITHCOORD", "WITHDIST", "WITHHASH"]
      options[:extras] = extras

      options
    end
  end
end

require 'set'
require 'redis/connection/registry'
require 'redis/connection/command_helper'
require "fakeredis/command_executor"
require "fakeredis/expiring_hash"
require "fakeredis/sort_method"
require "fakeredis/sorted_set_argument_handler"
require "fakeredis/sorted_set_store"
require "fakeredis/transaction_commands"
require "fakeredis/zset"
require "fakeredis/bitop_command"
require "fakeredis/geo_commands"
require "fakeredis/version"

class Redis
  module Connection
    DEFAULT_REDIS_VERSION = '3.3.5'

    class Memory
      include Redis::Connection::CommandHelper
      include FakeRedis
      include SortMethod
      include TransactionCommands
      include BitopCommand
      include GeoCommands
      include CommandExecutor

      attr_accessor :options

      # Tracks all databases for all instances across the current process.
      # We have to be able to handle two clients with the same host/port accessing
      # different databases at once without overwriting each other. So we store our
      # "data" outside the client instances, in this class level instance method.
      # Client instances access it with a key made up of their host/port, and then select
      # which DB out of the array of them they want. Allows the access we need.
      def self.databases
        @databases ||= Hash.new {|h,k| h[k] = [] }
      end

      # Used for resetting everything in specs
      def self.reset_all_databases
        @databases = nil
      end

      def self.channels
        @channels ||= Hash.new {|h,k| h[k] = [] }
      end

      def self.reset_all_channels
        @channels = nil
      end

      def self.connect(options = {})
        new(options)
      end

      def initialize(options = {})
        self.options = self.options ? self.options.merge(options) : options
      end

      def database_id
        @database_id ||= 0
      end

      attr_writer :database_id

      def database_instance_key
        [options[:host], options[:port]].hash
      end

      def databases
        self.class.databases[database_instance_key]
      end

      def find_database id=database_id
        databases[id] ||= ExpiringHash.new
      end

      def data
        find_database
      end

      def replies
        @replies ||= []
      end
      attr_writer :replies

      def connected?
        true
      end

      def connect_unix(path, timeout)
      end

      def disconnect
      end

      def client(command, _options = {})
        case command
        when :setname then "OK"
        when :getname then nil
        else
          raise Redis::CommandError, "ERR unknown command '#{command}'"
        end
      end

      def timeout=(usecs)
      end

      def read
        replies.shift
      end

      def flushdb
        databases.delete_at(database_id)
        "OK"
      end

      def flushall
        self.class.databases[database_instance_key] = []
        "OK"
      end

      def auth(password)
        "OK"
      end

      def select(index)
        data_type_check(index, Integer)
        self.database_id = index
        "OK"
      end

      def info
        {
          "redis_version" => options[:version] || DEFAULT_REDIS_VERSION,
          "connected_clients" => "1",
          "connected_slaves" => "0",
          "used_memory" => "3187",
          "changes_since_last_save" => "0",
          "last_save_time" => "1237655729",
          "total_connections_received" => "1",
          "total_commands_processed" => "1",
          "uptime_in_seconds" => "36000",
          "uptime_in_days" => 0
        }
      end

      def monitor; end

      def save; end

      def bgsave; end

      def bgrewriteaof; end

      def evalsha; end

      def eval; end

      def move key, destination_id
        raise Redis::CommandError, "ERR source and destination objects are the same" if destination_id == database_id
        destination = find_database(destination_id)
        return false unless data.has_key?(key)
        return false if destination.has_key?(key)
        destination[key] = data.delete(key)
        true
      end

      def dump(key)
        return nil unless exists(key)

        value = data[key]

        Marshal.dump(
          value: value,
          version: FakeRedis::VERSION, # Redis includes the version, so we might as well
        )
      end

      def restore(key, ttl, serialized_value)
        raise Redis::CommandError, "ERR Target key name is busy." if exists(key)

        raise Redis::CommandError, "ERR DUMP payload version or checksum are wrong" if serialized_value.nil?

        parsed_value = begin
          Marshal.load(serialized_value)
        rescue TypeError
          raise Redis::CommandError, "ERR DUMP payload version or checksum are wrong"
        end

        if parsed_value[:version] != FakeRedis::VERSION
          raise Redis::CommandError, "ERR DUMP payload version or checksum are wrong"
        end

        # We could figure out what type the key was and set it with the public API here,
        # or we could just assign the value. If we presume the serialized_value is only ever
        # a return value from `dump` then we've only been given something that was in
        # the internal data structure anyway.
        data[key] = parsed_value[:value]

        # Set a TTL if one has been passed
        ttl = ttl.to_i # Makes nil into 0
        expire(key, ttl / 1000) unless ttl.zero?

        "OK"
      end

      def get(key)
        data_type_check(key, String)
        data[key]
      end

      def getbit(key, offset)
        return unless data[key]
        data[key].unpack('B*')[0].split("")[offset].to_i
      end

      def bitcount(key, start_index = 0, end_index = -1)
        return 0 unless data[key]
        data[key][start_index..end_index].unpack('B*')[0].count("1")
      end

      def bitpos(key, bit, start_index = 0, end_index = -1)
        value = data[key] || ""
        value[0..end_index].unpack('B*')[0].index(bit.to_s, start_index * 8) || -1
      end

      def getrange(key, start, ending)
        return unless data[key]
        data[key][start..ending]
      end
      alias :substr :getrange

      def getset(key, value)
        data_type_check(key, String)
        data[key].tap do
          set(key, value)
        end
      end

      def mget(*keys)
        raise_argument_error('mget') if keys.empty?
        # We work with either an array, or list of arguments
        keys = keys.first if keys.size == 1
        data.values_at(*keys)
      end

      def append(key, value)
        data[key] = (data[key] || "")
        data[key] = data[key] + value.to_s
      end

      def strlen(key)
        return unless data[key]
        data[key].size
      end

      def hgetall(key)
        data_type_check(key, Hash)
        data[key].to_a.flatten || {}
      end

      def hget(key, field)
        data_type_check(key, Hash)
        data[key] && data[key][field.to_s]
      end

      def hdel(key, field)
        data_type_check(key, Hash)
        return 0 unless data[key]

        if field.is_a?(Array)
          old_keys_count = data[key].size
          fields = field.map(&:to_s)

          data[key].delete_if { |k, v| fields.include? k }
          deleted = old_keys_count - data[key].size
        else
          field = field.to_s
          deleted = data[key].delete(field) ? 1 : 0
        end

        remove_key_for_empty_collection(key)
        deleted
      end

      def hkeys(key)
        data_type_check(key, Hash)
        return [] if data[key].nil?
        data[key].keys
      end

      def hscan(key, start_cursor, *args)
        data_type_check(key, Hash)
        return ["0", []] unless data[key]

        match = "*"
        count = 10

        if args.size.odd?
          raise_argument_error('hscan')
        end

        if idx = args.index("MATCH")
          match = args[idx + 1]
        end

        if idx = args.index("COUNT")
          count = args[idx + 1]
        end

        start_cursor = start_cursor.to_i

        cursor = start_cursor
        next_keys = []

        if start_cursor + count >= data[key].length
          next_keys = (data[key].to_a)[start_cursor..-1]
          cursor = 0
        else
          cursor = start_cursor + count
          next_keys = (data[key].to_a)[start_cursor..cursor-1]
        end

        filtered_next_keys = next_keys.select{|k,v| File.fnmatch(match, k)}
        result = filtered_next_keys.flatten.map(&:to_s)

        return ["#{cursor}", result]
      end

      def keys(pattern = "*")
        data.keys.select { |key| File.fnmatch(pattern, key) }
      end

      def randomkey
        data.keys[rand(dbsize)]
      end

      def echo(string)
        string
      end

      def ping
        "PONG"
      end

      def lastsave
        Time.now.to_i
      end

      def time
        microseconds = (Time.now.to_f * 1000000).to_i
        [ microseconds / 1000000, microseconds % 1000000 ]
      end

      def dbsize
        data.keys.count
      end

      def exists(key)
        data.key?(key)
      end

      def llen(key)
        data_type_check(key, Array)
        return 0 unless data[key]
        data[key].size
      end

      def lrange(key, startidx, endidx)
        data_type_check(key, Array)
        if data[key]
          # In Ruby when negative start index is out of range Array#slice returns
          # nil which is not the case for lrange in Redis.
          startidx = 0 if startidx < 0 && startidx.abs > data[key].size
          data[key][startidx..endidx] || []
        else
          []
        end
      end

      def ltrim(key, start, stop)
        data_type_check(key, Array)
        return unless data[key]

        # Example: we have a list of 3 elements and
        # we give it a ltrim list, -5, -1. This means
        # it should trim to a max of 5. Since 3 < 5
        # we should not touch the list. This is consistent
        # with behavior of real Redis's ltrim with a negative
        # start argument.
        unless start < 0 && data[key].count < start.abs
          data[key] = data[key][start..stop]
        end

        "OK"
      end

      def lindex(key, index)
        data_type_check(key, Array)
        data[key] && data[key][index]
      end

      def linsert(key, where, pivot, value)
        data_type_check(key, Array)
        return unless data[key]

        value = value.to_s
        index = data[key].index(pivot.to_s)
        return -1 if index.nil?

        case where.to_s
          when /\Abefore\z/i then data[key].insert(index, value)
          when /\Aafter\z/i  then data[key].insert(index + 1, value)
          else raise_syntax_error
        end
      end

      def lset(key, index, value)
        data_type_check(key, Array)
        return unless data[key]
        raise Redis::CommandError, "ERR index out of range" if index >= data[key].size
        data[key][index] = value.to_s
      end

      def lrem(key, count, value)
        data_type_check(key, Array)
        return 0 unless data[key]

        value = value.to_s
        old_size = data[key].size
        diff =
          if count == 0
            data[key].delete(value)
            old_size - data[key].size
          else
            array = count > 0 ? data[key].dup : data[key].reverse
            count.abs.times{ array.delete_at(array.index(value) || array.length) }
            data[key] = count > 0 ? array.dup : array.reverse
            old_size - data[key].size
          end
        remove_key_for_empty_collection(key)
        diff
      end

      def rpush(key, value)
        raise_argument_error('rpush') if value.respond_to?(:each) && value.empty?
        data_type_check(key, Array)
        data[key] ||= []
        [value].flatten.each do |val|
          data[key].push(val.to_s)
        end
        data[key].size
      end

      def rpushx(key, value)
        raise_argument_error('rpushx') if value.respond_to?(:each) && value.empty?
        data_type_check(key, Array)
        return unless data[key]
        rpush(key, value)
      end

      def lpush(key, value)
        raise_argument_error('lpush') if value.respond_to?(:each) && value.empty?
        data_type_check(key, Array)
        data[key] ||= []
        [value].flatten.each do |val|
          data[key].unshift(val.to_s)
        end
        data[key].size
      end

      def lpushx(key, value)
        raise_argument_error('lpushx') if value.respond_to?(:each) && value.empty?
        data_type_check(key, Array)
        return unless data[key]
        lpush(key, value)
      end

      def rpop(key)
        data_type_check(key, Array)
        return unless data[key]
        data[key].pop
      end

      def brpop(keys, timeout=0)
        #todo threaded mode
        keys = Array(keys)
        keys.each do |key|
          if data[key] && data[key].size > 0
            return [key, data[key].pop]
          end
        end
        sleep(timeout.to_f)
        nil
      end

      def rpoplpush(key1, key2)
        data_type_check(key1, Array)
        rpop(key1).tap do |elem|
          lpush(key2, elem) unless elem.nil?
        end
      end

      def brpoplpush(key1, key2, opts={})
        data_type_check(key1, Array)
        _key, elem = brpop(key1)
        lpush(key2, elem) unless elem.nil?
        elem
      end

      def lpop(key)
        data_type_check(key, Array)
        return unless data[key]
        data[key].shift
      end

      def blpop(keys, timeout=0)
        #todo threaded mode
        keys = Array(keys)
        keys.each do |key|
          if data[key] && data[key].size > 0
            return [key, data[key].shift]
          end
        end
        sleep(timeout.to_f)
        nil
      end

      def smembers(key)
        data_type_check(key, ::Set)
        return [] unless data[key]
        data[key].to_a.reverse
      end

      def sismember(key, value)
        data_type_check(key, ::Set)
        return false unless data[key]
        data[key].include?(value.to_s)
      end

      def sadd(key, value)
        data_type_check(key, ::Set)
        value = Array(value)
        raise_argument_error('sadd') if value.empty?

        result = if data[key]
          old_set = data[key].dup
          data[key].merge(value.map(&:to_s))
          (data[key] - old_set).size
        else
          data[key] = ::Set.new(value.map(&:to_s))
          data[key].size
        end

        # 0 = false, 1 = true, 2+ untouched
        return result == 1 if result < 2
        result
      end

      def srem(key, value)
        data_type_check(key, ::Set)
        value = Array(value)
        raise_argument_error('srem') if value.empty?
        return false unless data[key]

        if value.is_a?(Array)
          old_size = data[key].size
          values = value.map(&:to_s)
          values.each { |v| data[key].delete(v) }
          deleted = old_size - data[key].size
        else
          deleted = !!data[key].delete?(value.to_s)
        end

        remove_key_for_empty_collection(key)
        deleted
      end

      def smove(source, destination, value)
        data_type_check(destination, ::Set)
        result = self.srem(source, value)
        self.sadd(destination, value) if result
        result
      end

      def spop(key, count = nil)
        data_type_check(key, ::Set)
        results = (count || 1).times.map do
          elem = srandmember(key)
          srem(key, elem) if elem
          elem
        end.compact
        count.nil? ? results.first : results
      end

      def scard(key)
        data_type_check(key, ::Set)
        return 0 unless data[key]
        data[key].size
      end

      def sinter(*keys)
        keys = keys[0] if flatten?(keys)
        raise_argument_error('sinter') if keys.empty?

        keys.each { |k| data_type_check(k, ::Set) }
        return ::Set.new if keys.any? { |k| data[k].nil? }
        keys = keys.map { |k| data[k] || ::Set.new }
        keys.inject do |set, key|
          set & key
        end.to_a
      end

      def sinterstore(destination, *keys)
        data_type_check(destination, ::Set)
        result = sinter(*keys)
        data[destination] = ::Set.new(result)
      end

      def sunion(*keys)
        keys = keys[0] if flatten?(keys)
        raise_argument_error('sunion') if keys.empty?

        keys.each { |k| data_type_check(k, ::Set) }
        keys = keys.map { |k| data[k] || ::Set.new }
        keys.inject(::Set.new) do |set, key|
          set | key
        end.to_a
      end

      def sunionstore(destination, *keys)
        data_type_check(destination, ::Set)
        result = sunion(*keys)
        data[destination] = ::Set.new(result)
      end

      def sdiff(key1, *keys)
        keys = keys[0] if flatten?(keys)
        [key1, *keys].each { |k| data_type_check(k, ::Set) }
        keys = keys.map { |k| data[k] || ::Set.new }
        keys.inject(data[key1] || Set.new) do |memo, set|
          memo - set
        end.to_a
      end

      def sdiffstore(destination, key1, *keys)
        data_type_check(destination, ::Set)
        result = sdiff(key1, *keys)
        data[destination] = ::Set.new(result)
      end

      def srandmember(key, number=nil)
        number.nil? ? srandmember_single(key) : srandmember_multiple(key, number)
      end

      def sscan(key, start_cursor, *args)
        data_type_check(key, ::Set)
        return ["0", []] unless data[key]

        match = "*"
        count = 10

        if args.size.odd?
          raise_argument_error('sscan')
        end

        if idx = args.index("MATCH")
          match = args[idx + 1]
        end

        if idx = args.index("COUNT")
          count = args[idx + 1]
        end

        start_cursor = start_cursor.to_i

        cursor = start_cursor
        next_keys = []

        if start_cursor + count >= data[key].length
          next_keys = (data[key].to_a)[start_cursor..-1]
          cursor = 0
        else
          cursor = start_cursor + count
          next_keys = (data[key].to_a)[start_cursor..cursor-1]
        end

        filtered_next_keys = next_keys.select{ |k,v| File.fnmatch(match, k)}
        result = filtered_next_keys.flatten.map(&:to_s)

        return ["#{cursor}", result]
      end

      def del(*keys)
        delete_keys(keys, 'del')
      end

      def unlink(*keys)
        delete_keys(keys, 'unlink')
      end

      def setnx(key, value)
        if exists(key)
          0
        else
          set(key, value)
          1
        end
      end

      def rename(key, new_key)
        return unless data[key]
        data[new_key] = data[key]
        data.expires[new_key] = data.expires[key] if data.expires.include?(key)
        data.delete(key)
      end

      def renamenx(key, new_key)
        if exists(new_key)
          false
        else
          rename(key, new_key)
          true
        end
      end

      def expire(key, ttl)
        return 0 unless data[key]
        data.expires[key] = Time.now + ttl
        1
      end

      def pexpire(key, ttl)
        return 0 unless data[key]
        data.expires[key] = Time.now + (ttl / 1000.0)
        1
      end

      def ttl(key)
        if data.expires.include?(key) && (ttl = data.expires[key].to_i - Time.now.to_i) > 0
          ttl
        else
          exists(key) ? -1 : -2
        end
      end

      def pttl(key)
        if data.expires.include?(key) && (ttl = data.expires[key].to_f - Time.now.to_f) > 0
          ttl * 1000
        else
          exists(key) ? -1 : -2
        end
      end

      def expireat(key, timestamp)
        data.expires[key] = Time.at(timestamp)
        true
      end

      def persist(key)
        !!data.expires.delete(key)
      end

      def hset(key, field, value)
        data_type_check(key, Hash)
        field = field.to_s
        if data[key]
          result = !data[key].include?(field)
          data[key][field] = value.to_s
          result ? 1 : 0
        else
          data[key] = { field => value.to_s }
          1
        end
      end

      def hsetnx(key, field, value)
        data_type_check(key, Hash)
        field = field.to_s
        return false if data[key] && data[key][field]
        hset(key, field, value)
      end

      def hmset(key, *fields)
        # mapped_hmset gives us [[:k1, "v1", :k2, "v2"]] for `fields`. Fix that.
        fields = fields[0] if mapped_param?(fields)
        raise_argument_error('hmset') if fields.empty?

        is_list_of_arrays = fields.all?{|field| field.instance_of?(Array)}

        raise_argument_error('hmset') if fields.size.odd? and !is_list_of_arrays
        raise_argument_error('hmset') if is_list_of_arrays and !fields.all?{|field| field.length == 2}

        data_type_check(key, Hash)
        data[key] ||= {}

        if is_list_of_arrays
          fields.each do |pair|
            data[key][pair[0].to_s] = pair[1].to_s
          end
        else
          fields.each_slice(2) do |field|
            data[key][field[0].to_s] = field[1].to_s
          end
        end
        "OK"
      end

      def hmget(key, *fields)
        raise_argument_error('hmget')  if fields.empty? || fields.flatten.empty?

        data_type_check(key, Hash)
        fields.flatten.map do |field|
          field = field.to_s
          if data[key]
            data[key][field]
          else
            nil
          end
        end
      end

      def hlen(key)
        data_type_check(key, Hash)
        return 0 unless data[key]
        data[key].size
      end

      def hstrlen(key, field)
        data_type_check(key, Hash)
        return 0 if data[key].nil? || data[key][field].nil?
        data[key][field].size
      end

      def hvals(key)
        data_type_check(key, Hash)
        return [] unless data[key]
        data[key].values
      end

      def hincrby(key, field, increment)
        data_type_check(key, Hash)
        field = field.to_s
        if data[key]
          data[key][field] = (data[key][field].to_i + increment.to_i).to_s
        else
          data[key] = { field => increment.to_s }
        end
        data[key][field].to_i
      end

      def hincrbyfloat(key, field, increment)
        data_type_check(key, Hash)
        field = field.to_s
        if data[key]
          data[key][field] = (data[key][field].to_f + increment.to_f).to_s
        else
          data[key] = { field => increment.to_s }
        end
        data[key][field]
      end

      def hexists(key, field)
        data_type_check(key, Hash)
        return false unless data[key]
        data[key].key?(field.to_s)
      end

      def sync ; end

      def set(key, value, *array_options)
        option_nx = array_options.delete("NX")
        option_xx = array_options.delete("XX")

        return nil if option_nx && option_xx

        return nil if option_nx && exists(key)
        return nil if option_xx && !exists(key)

        data[key] = value.to_s

        options = Hash[array_options.each_slice(2).to_a]
        ttl_in_seconds = options["EX"] if options["EX"]
        ttl_in_seconds = options["PX"] / 1000.0 if options["PX"]

        expire(key, ttl_in_seconds) if ttl_in_seconds

        "OK"
      end

      def setbit(key, offset, bit)
        old_val = data[key] ? data[key].unpack('B*')[0].split("") : []
        size_increment = [((offset/8)+1)*8-old_val.length, 0].max
        old_val += Array.new(size_increment).map{"0"}
        original_val = old_val[offset].to_i
        old_val[offset] = bit.to_s
        new_val = ""
        old_val.each_slice(8){|b| new_val = new_val + b.join("").to_i(2).chr }
        data[key] = new_val
        original_val
      end

      def setex(key, seconds, value)
        data[key] = value.to_s
        expire(key, seconds)
        "OK"
      end

      def psetex(key, milliseconds, value)
        setex(key, milliseconds / 1000.0, value)
      end

      def setrange(key, offset, value)
        return unless data[key]
        s = data[key][offset,value.size]
        data[key][s] = value
      end

      def mset(*pairs)
        # Handle pairs for mapped_mset command
        pairs = pairs[0] if mapped_param?(pairs)
        raise_argument_error('mset') if pairs.empty? || pairs.size == 1
        # We have to reply with a different error message here to be consistent with redis-rb 3.0.6 / redis-server 2.8.1
        raise_argument_error("mset", "mset_odd") if pairs.size.odd?

        pairs.each_slice(2) do |pair|
          data[pair[0].to_s] = pair[1].to_s
        end
        "OK"
      end

      def msetnx(*pairs)
        # Handle pairs for mapped_msetnx command
        pairs = pairs[0] if mapped_param?(pairs)
        keys = []
        pairs.each_with_index{|item, index| keys << item.to_s if index % 2 == 0}
        return false if keys.any?{|key| data.key?(key) }
        mset(*pairs)
        true
      end

      def incr(key)
        data.merge!({ key => (data[key].to_i + 1).to_s || "1"})
        data[key].to_i
      end

      def incrby(key, by)
        data.merge!({ key => (data[key].to_i + by.to_i).to_s || by })
        data[key].to_i
      end

      def incrbyfloat(key, by)
        data.merge!({ key => (data[key].to_f + by.to_f).to_s || by })
        data[key]
      end

      def decr(key)
        data.merge!({ key => (data[key].to_i - 1).to_s || "-1"})
        data[key].to_i
      end

      def decrby(key, by)
        data.merge!({ key => ((data[key].to_i - by.to_i) || (by.to_i * -1)).to_s })
        data[key].to_i
      end

      def type(key)
        case data[key]
          when nil then "none"
          when String then "string"
          when ZSet then "zset"
          when Hash then "hash"
          when Array then "list"
          when ::Set then "set"
        end
      end

      def quit ; end

      def shutdown; end

      def slaveof(host, port) ; end

      def scan(start_cursor, *args)
        match = "*"
        count = 10

        if idx = args.index("MATCH")
          match = args[idx + 1]
        end

        if idx = args.index("COUNT")
          count = args[idx + 1]
        end

        start_cursor = start_cursor.to_i
        data_type_check(start_cursor, Integer)

        cursor = start_cursor
        returned_keys = []
        final_page = start_cursor + count >= keys(match).length

        if final_page
          previous_keys_been_deleted = (count >= keys(match).length)
          start_index = previous_keys_been_deleted ? 0 : cursor

          returned_keys = keys(match)[start_index..-1]
          cursor = 0
        else
          end_index = start_cursor + (count - 1)
          returned_keys = keys(match)[start_cursor..end_index]
          cursor = start_cursor + count
        end

        return "#{cursor}", returned_keys
      end

      def zadd(key, *args)
        option_xx = args.delete("XX")
        option_nx = args.delete("NX")
        option_ch = args.delete("CH")
        option_incr = args.delete("INCR")

        if option_xx && option_nx
          raise_options_error("XX", "NX")
        end

        if option_incr && args.size > 2
          raise_options_error("INCR")
        end

        if !args.first.is_a?(Array)
          if args.size < 2
            raise_argument_error('zadd')
          elsif args.size.odd?
            raise_syntax_error
          end
        else
          unless args.all? {|pair| pair.size == 2 }
            raise_syntax_error
          end
        end

        data_type_check(key, ZSet)
        data[key] ||= ZSet.new

        # Turn [1, 2, 3, 4] into [[1, 2], [3, 4]] unless it is already
        args = args.each_slice(2).to_a unless args.first.is_a?(Array)

        changed = 0
        exists = args.map(&:last).count { |el| !hexists(key, el.to_s) }

        args.each do |score, value|
          if option_nx && hexists(key, value.to_s)
            next
          end

          if option_xx && !hexists(key, value.to_s)
            exists -= 1
            next
          end

          if option_incr
            data[key][value.to_s] ||= 0
            return data[key].increment(value, score).to_s
          end

          if option_ch && data[key][value.to_s] != score
            changed += 1
          end
          data[key][value.to_s] = score
        end

        if option_incr
          changed = changed.zero? ? nil : changed
          exists = exists.zero? ? nil : exists
        end

        option_ch ? changed : exists
      end

      def zrem(key, value)
        data_type_check(key, ZSet)
        values = Array(value)
        return 0 unless data[key]

        response = values.map do |v|
          data[key].delete(v.to_s) if data[key].has_key?(v.to_s)
        end.compact.size

        remove_key_for_empty_collection(key)
        response
      end

      def zpopmax(key, count = nil)
        data_type_check(key, ZSet)
        return [] unless data[key]
        sorted_members = sort_keys(data[key])
        results = sorted_members.last(count || 1).reverse!
        results.each do |member|
          zrem(key, member.first)
        end
        count.nil? ? results.first : results.flatten
      end

      def zpopmin(key, count = nil)
        data_type_check(key, ZSet)
        return [] unless data[key]
        sorted_members = sort_keys(data[key])
        results = sorted_members.first(count || 1)
        results.each do |member|
          zrem(key, member.first)
        end
        count.nil? ? results.first : results.flatten
      end

      def bzpopmax(*args)
        bzpop(:bzpopmax, args)
      end

      def bzpopmin(*args)
        bzpop(:bzpopmin, args)
      end

      def zcard(key)
        data_type_check(key, ZSet)
        data[key] ? data[key].size : 0
      end

      def zscore(key, value)
        data_type_check(key, ZSet)
        value = data[key] && data[key][value.to_s]
        if value == Float::INFINITY
          "inf"
        elsif value == -Float::INFINITY
          "-inf"
        elsif value
          value.to_s
        end
      end

      def zcount(key, min, max)
        data_type_check(key, ZSet)
        return 0 unless data[key]
        data[key].select_by_score(min, max).size
      end

      def zincrby(key, num, value)
        data_type_check(key, ZSet)
        data[key] ||= ZSet.new
        data[key][value.to_s] ||= 0
        data[key].increment(value.to_s, num)

        if num =~ /^\+?inf/
          "inf"
        elsif num == "-inf"
          "-inf"
        else
          data[key][value.to_s].to_s
        end
      end

      def zrank(key, value)
        data_type_check(key, ZSet)
        z = data[key]
        return unless z
        z.keys.sort_by {|k| z[k] }.index(value.to_s)
      end

      def zrevrank(key, value)
        data_type_check(key, ZSet)
        z = data[key]
        return unless z
        z.keys.sort_by {|k| -z[k] }.index(value.to_s)
      end

      def zrange(key, start, stop, with_scores = nil)
        data_type_check(key, ZSet)
        return [] unless data[key]

        results = sort_keys(data[key])
        # Select just the keys unless we want scores
        results = results.map(&:first) unless with_scores
        start = [start, -results.size].max
        (results[start..stop] || []).flatten.map(&:to_s)
      end

      def zrangebylex(key, start, stop, *opts)
        data_type_check(key, ZSet)
        return [] unless data[key]
        zset = data[key]

        sorted = if zset.identical_scores?
          zset.keys.sort { |x, y| x.to_s <=> y.to_s }
        else
          zset.keys
        end

        range = get_range start, stop, sorted.first, sorted.last

        filtered = []
        sorted.each do |element|
          filtered << element if (range[0][:value]..range[1][:value]).cover?(element)
        end
        filtered.shift if filtered[0] == range[0][:value] && !range[0][:inclusive]
        filtered.pop if filtered.last == range[1][:value] && !range[1][:inclusive]

        limit = get_limit(opts, filtered)
        if limit
          filtered = filtered[limit[0]..-1].take(limit[1])
        end

        filtered
      end

      def zrevrangebylex(key, start, stop, *args)
        zrangebylex(key, stop, start, args).reverse
      end

      def zrevrange(key, start, stop, with_scores = nil)
        data_type_check(key, ZSet)
        return [] unless data[key]

        if with_scores
          data[key].sort_by {|_,v| -v }
        else
          data[key].keys.sort_by {|k| -data[key][k] }
        end[start..stop].flatten.map(&:to_s)
      end

      def zrangebyscore(key, min, max, *opts)
        data_type_check(key, ZSet)
        return [] unless data[key]

        range = data[key].select_by_score(min, max)
        vals = if opts.include?('WITHSCORES')
          range.sort_by {|_,v| v }
        else
          range.keys.sort_by {|k| range[k] }
        end

        limit = get_limit(opts, vals)
        vals = vals[*limit] if limit

        vals.flatten.map(&:to_s)
      end

      def zrevrangebyscore(key, max, min, *opts)
        opts = opts.flatten
        data_type_check(key, ZSet)
        return [] unless data[key]

        range = data[key].select_by_score(min, max)
        vals = if opts.include?('WITHSCORES')
          range.sort_by {|_,v| -v }
        else
          range.keys.sort_by {|k| -range[k] }
        end

        limit = get_limit(opts, vals)
        vals = vals[*limit] if limit

        vals.flatten.map(&:to_s)
      end

      def zremrangebyscore(key, min, max)
        data_type_check(key, ZSet)
        return 0 unless data[key]

        range = data[key].select_by_score(min, max)
        range.each {|k,_| data[key].delete(k) }
        range.size
      end

      def zremrangebyrank(key, start, stop)
        data_type_check(key, ZSet)
        return 0 unless data[key]

        sorted_elements = data[key].sort_by { |k, v| v }
        start = sorted_elements.length if start > sorted_elements.length
        elements_to_delete = sorted_elements[start..stop]
        elements_to_delete.each { |elem, rank| data[key].delete(elem) }
        elements_to_delete.size
      end

      def zinterstore(out, *args)
        data_type_check(out, ZSet)
        args_handler = SortedSetArgumentHandler.new(args)
        data[out] = SortedSetIntersectStore.new(args_handler, data).call
        data[out].size
      end

      def zunionstore(out, *args)
        data_type_check(out, ZSet)
        args_handler = SortedSetArgumentHandler.new(args)
        data[out] = SortedSetUnionStore.new(args_handler, data).call
        data[out].size
      end

      def pfadd(key, member)
        data_type_check(key, Set)
        data[key] ||= Set.new
        previous_size = data[key].size
        data[key] |= Array(member)
        data[key].size != previous_size
      end

      def pfcount(*keys)
        keys = keys.flatten
        raise_argument_error("pfcount") if keys.empty?
        keys.each { |key| data_type_check(key, Set) }
        if keys.count == 1
          (data[keys.first] || Set.new).size
        else
          union = keys.map { |key| data[key] }.compact.reduce(&:|)
          union.size
        end
      end

      def pfmerge(destination, *sources)
        sources.each { |source| data_type_check(source, Set) }
        union = sources.map { |source| data[source] || Set.new }.reduce(&:|)
        data[destination] = union
        "OK"
      end

      def subscribe(*channels)
        raise_argument_error('subscribe') if channels.empty?()

        #Create messages for all data from the channels
        channel_replies = channels.map do |channel|
          self.class.channels[channel].slice!(0..-1).map!{|v| ["message", channel, v]}
        end
        channel_replies.flatten!(1)
        channel_replies.compact!()

        #Put messages into the replies for the future
        channels.each_with_index do |channel,index|
          replies << ["subscribe", channel, index+1]
        end
        replies.push(*channel_replies)

        #Add unsubscribe message to stop blocking (see https://github.com/redis/redis-rb/blob/v3.2.1/lib/redis/subscribe.rb#L38)
        replies.push(self.unsubscribe())

        replies.pop() #Last reply will be pushed back on
      end

      def psubscribe(*patterns)
        raise_argument_error('psubscribe') if patterns.empty?()

        #Create messages for all data from the channels
        channel_replies = self.class.channels.keys.map do |channel|
          pattern = patterns.find{|p| File.fnmatch(p, channel) }
          unless pattern.nil?()
            self.class.channels[channel].slice!(0..-1).map!{|v| ["pmessage", pattern, channel, v]}
          end
        end
        channel_replies.flatten!(1)
        channel_replies.compact!()

        #Put messages into the replies for the future
        patterns.each_with_index do |pattern,index|
          replies << ["psubscribe", pattern, index+1]
        end
        replies.push(*channel_replies)

        #Add unsubscribe to stop blocking
        replies.push(self.punsubscribe())

        replies.pop() #Last reply will be pushed back on
      end

      def publish(channel, message)
        self.class.channels[channel] << message
        0 #Just fake number of subscribers
      end

      def unsubscribe(*channels)
        if channels.empty?()
          replies << ["unsubscribe", nil, 0]
        else
          channels.each do |channel|
            replies << ["unsubscribe", channel, 0]
          end
        end
        replies.pop() #Last reply will be pushed back on
      end

      def punsubscribe(*patterns)
        if patterns.empty?()
          replies << ["punsubscribe", nil, 0]
        else
          patterns.each do |pattern|
            replies << ["punsubscribe", pattern, 0]
          end
        end
        replies.pop() #Last reply will be pushed back on
      end

      def zscan(key, start_cursor, *args)
        data_type_check(key, ZSet)
        return [] unless data[key]

        match = "*"
        count = 10

        if args.size.odd?
          raise_argument_error('zscan')
        end

        if idx = args.index("MATCH")
          match = args[idx + 1]
        end

        if idx = args.index("COUNT")
          count = args[idx + 1]
        end

        start_cursor = start_cursor.to_i
        data_type_check(start_cursor, Integer)

        cursor = start_cursor
        next_keys = []

        sorted_keys = sort_keys(data[key])

        if start_cursor + count >= sorted_keys.length
          next_keys = sorted_keys.to_a.select { |k| File.fnmatch(match, k[0]) } [start_cursor..-1]
          cursor = 0
        else
          cursor = start_cursor + count
          next_keys = sorted_keys.to_a.select { |k| File.fnmatch(match, k[0]) } [start_cursor..cursor-1]
        end
        return "#{cursor}", next_keys.flatten.map(&:to_s)
      end

      # Originally from redis-rb
      def zscan_each(key, *args, &block)
        data_type_check(key, ZSet)
        return [] unless data[key]

        return to_enum(:zscan_each, key, options) unless block_given?
        cursor = 0
        loop do
          cursor, values = zscan(key, cursor, options)
          values.each(&block)
          break if cursor == "0"
        end
      end

      private
        def raise_argument_error(command, match_string=command)
          error_message = if %w(hmset mset_odd).include?(match_string.downcase)
            "ERR wrong number of arguments for #{command.upcase}"
          else
            "ERR wrong number of arguments for '#{command}' command"
          end

          raise Redis::CommandError, error_message
        end

        def raise_syntax_error
          raise Redis::CommandError, "ERR syntax error"
        end

        def raise_options_error(*options)
          if options.detect { |opt| opt.match(/incr/i) }
            error_message = "ERR INCR option supports a single increment-element pair"
          else
            error_message = "ERR #{options.join(" and ")} options at the same time are not compatible"
          end
          raise Redis::CommandError, error_message
        end

        def raise_command_error(message)
          raise Redis::CommandError, message
        end

        def delete_keys(keys, command)
          keys = keys.flatten(1)
          raise_argument_error(command) if keys.empty?

          old_count = data.keys.size
          keys.each do |key|
            data.delete(key)
          end
          old_count - data.keys.size
        end

        def remove_key_for_empty_collection(key)
          del(key) if data[key] && data[key].empty?
        end

        def data_type_check(key, klass)
          if data[key] && !data[key].is_a?(klass)
            raise Redis::CommandError.new("WRONGTYPE Operation against a key holding the wrong kind of value")
          end
        end

        def get_range(start, stop, min = -Float::INFINITY, max = Float::INFINITY)
          range_options = []

          [start, stop].each do |value|
            case value[0]
            when "-"
              range_options << { value: min, inclusive: true }
            when "+"
              range_options << { value: max, inclusive: true }
            when "["
              range_options << { value: value[1..-1], inclusive: true }
            when "("
              range_options << { value: value[1..-1], inclusive: false }
            else
              raise Redis::CommandError, "ERR min or max not valid string range item"
            end
          end

          range_options
        end

        def get_limit(opts, vals)
          index = opts.index('LIMIT')

          if index
            offset = opts[index + 1]

            count = opts[index + 2]
            count = vals.size if count < 0

            [offset, count]
          end
        end

        def mapped_param? param
          param.size == 1 && param[0].is_a?(Array)
        end
        # NOTE : Redis-rb 3.x will flatten *args, so method(["a", "b", "c"])
        #        should be handled the same way as method("a", "b", "c")
        alias_method :flatten?, :mapped_param?

        def srandmember_single(key)
          data_type_check(key, ::Set)
          return nil unless data[key]
          data[key].to_a[rand(data[key].size)]
        end

        def srandmember_multiple(key, number)
          return [] unless data[key]
          if number >= 0
            # replace with `data[key].to_a.sample(number)` when 1.8.7 is deprecated
            (1..number).inject([]) do |selected, _|
              available_elements = data[key].to_a - selected
              selected << available_elements[rand(available_elements.size)]
            end.compact
          else
            (1..-number).map { data[key].to_a[rand(data[key].size)] }.flatten
          end
        end

        def bzpop(command, args)
          timeout =
            if args.last.is_a?(Hash)
              args.pop[:timeout]
            elsif args.last.respond_to?(:to_int)
              args.pop.to_int
            end

          timeout ||= 0
          single_pop_command = command.to_s[1..-1]
          keys = args.flatten
          keys.each do |key|
            if data[key]
              data_type_check(data[key], ZSet)
              if data[key].size > 0
                result = public_send(single_pop_command, key)
                return result.unshift(key)
              end
            end
          end
          sleep(timeout.to_f)
          nil
        end

        def sort_keys(arr)
          # Sort by score, or if scores are equal, key alphanum
          arr.sort do |(k1, v1), (k2, v2)|
            if v1 == v2
              k1 <=> k2
            else
              v1 <=> v2
            end
          end
        end
    end
  end
end

# FIXME this line should be deleted as explicit enabling is better
Redis::Connection.drivers << Redis::Connection::Memory

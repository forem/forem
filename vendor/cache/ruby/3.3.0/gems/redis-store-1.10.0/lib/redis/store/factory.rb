require 'cgi'
require 'uri'

class Redis
  class Store < self
    class Factory
      DEFAULT_PORT = 6379

      def self.create(*options)
        new(options).create
      end

      def initialize(*options)
        @addresses = []
        @options   = {}
        extract_addresses_and_options(options)
      end

      def create
        if @addresses.empty?
          @addresses << {}
        end

        if @addresses.size > 1
          ::Redis::DistributedStore.new @addresses, @options
        else
          ::Redis::Store.new @addresses.first.merge(@options)
        end
      end

      def self.resolve(uri) #:api: private
        if uri.is_a?(Hash)
          extract_host_options_from_hash(uri)
        else
          extract_host_options_from_uri(uri)
        end
      end

      def self.extract_host_options_from_hash(options)
        options = normalize_key_names(options)
        if host_options?(options)
          options
        else
          nil
        end
      end

      def self.normalize_key_names(options)
        options = options.dup
        if options.key?(:key_prefix) && !options.key?(:namespace)
          options[:namespace] = options.delete(:key_prefix) # RailsSessionStore
        end
        options[:raw] = case
                        when options.key?(:serializer)
                          options[:serializer].nil?
                        when options.key?(:marshalling)
                          !options[:marshalling]
                        else
                          false
        end
        options
      end

      def self.host_options?(options)
        options.keys.any? { |n| [:host, :db, :port, :path].include?(n) }
      end

      def self.extract_host_options_from_uri(uri)
        uri = URI.parse(uri)
        if uri.scheme == "unix"
          options = { :path => uri.path }
        else
          _, db, namespace = if uri.path
            uri.path.split(/\//)
          end

          options = {
            :scheme   => uri.scheme,
            :host     => uri.hostname,
            :port     => uri.port || DEFAULT_PORT,
            :password => uri.password.nil? ? nil : CGI.unescape(uri.password.to_s)
          }

          options[:db]        = db.to_i   if db
          options[:namespace] = namespace if namespace
        end
        if uri.query
          query = Hash[URI.decode_www_form(uri.query)]
          query.each do |(key, value)|
            options[key.to_sym] = value
          end
        end

        options
      end

      private

        def extract_addresses_and_options(*options)
          options.flatten.compact.each do |token|
            resolved = self.class.resolve(token)
            if resolved
              @addresses << resolved
            else
              @options.merge!(self.class.normalize_key_names(token))
            end
          end
        end
    end
  end
end

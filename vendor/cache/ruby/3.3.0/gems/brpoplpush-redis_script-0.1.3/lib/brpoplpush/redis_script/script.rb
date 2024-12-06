# frozen_string_literal: true

module Brpoplpush
  module RedisScript
    # Interface to dealing with .lua files
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Script
      def self.load(name, root_path, conn)
        script = new(name: name, root_path: root_path)
        script.load(conn)
      end

      #
      # @!attribute [r] script_name
      #   @return [Symbol, String] the name of the script without extension
      attr_reader :name
      #
      # @!attribute [r] script_path
      #   @return [String] the path to the script on disk
      attr_reader :path
      #
      # @!attribute [r] root_path
      #   @return [Pathname]
      attr_reader :root_path
      #
      # @!attribute [r] source
      #   @return [String] the source code of the lua script
      attr_reader :source
      #
      # @!attribute [rw] sha
      #   @return [String] the sha of the script
      attr_reader :sha
      #
      # @!attribute [rw] call_count
      #   @return [Integer] the number of times the script was called/executed
      attr_reader :call_count

      def initialize(name:, root_path:)
        @name      = name
        @root_path = root_path
        @path      = root_path.join("#{name}.lua").to_s
        @source    = render_file
        @sha       = compiled_sha
        @call_count = 0
      end

      def ==(other)
        sha == compiled_sha && compiled_sha == other.sha
      end

      def increment_call_count
        @call_count += 1
      end

      def changed?
        compiled_sha != sha
      end

      def render_file
        Template.new(root_path).render(path)
      end

      def compiled_sha
        Digest::SHA1.hexdigest(source)
      end

      def load(conn)
        @sha =
          if conn.respond_to?(:namespace)
            conn.redis.script(:load, source)
          else
            conn.script(:load, source)
          end

        self
      end
    end
  end
end

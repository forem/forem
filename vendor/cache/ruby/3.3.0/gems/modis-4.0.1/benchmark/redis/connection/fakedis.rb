# rubocop:disable all

require 'fileutils'
require 'redis/connection/hiredis'

class Redis
  module Connection
    class Fakedis < ::Redis::Connection::Hiredis
      class << self
        attr_accessor :reads, :read_indicies, :replaying, :recording
        alias_method :replaying?, :replaying
        alias_method :recording?, :recording
      end

      @reads = []
      @read_indicies = []

      def self.start_replay(name)
        puts "Fakedis replaying."
        self.replaying = true

        @reads = Marshal.load(File.read(reads_path(name)))
        @read_indicies = Marshal.load(File.read(read_indicies_path(name)))
      end

      def self.start_recording
        puts "Fakedis recording."
        self.recording = true
      end

      def self.stop_recording(name)
        self.recording = false

        puts "\nFakedis:"
        puts " * #{reads.size} unique reads recorded"

        FileUtils.mkdir_p("tmp/fakedis")

        File.open(reads_path(name), 'w') { |fd| fd.write(Marshal.dump(reads)) }
        File.open(read_indicies_path(name), 'w') { |fd| fd.write(Marshal.dump(read_indicies)) }
      end

      def self.reads_path(name)
        "tmp/fakedis/#{name}_reads.dump"
      end

      def self.read_indicies_path(name)
        "tmp/fakedis/#{name}_read_indicies.dump"
      end

      def initialize(*args)
        super
        @reads_idx = -1
        @read_depth = 0
      end

      def read
        if self.class.recording?
          @read_depth += 1
          v = super
          @read_depth -= 1
          return v if @read_depth > 0
          i = self.class.reads.index(v)

          if i
            self.class.read_indicies << i
          else
            self.class.reads << v
            self.class.read_indicies << self.class.reads.size - 1
          end

          v
        elsif self.class.replaying?
          @reads_idx += 1
          self.class.reads[self.class.read_indicies[@reads_idx]]
        else
          super
        end
      end

      def write(v)
        if self.class.replaying?
          # Do nothing.
        else
          super
        end
      end
    end
  end
end

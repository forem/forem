module Zip
  # Info-ZIP Additional timestamp field
  class ExtraField::UniversalTime < ExtraField::Generic
    HEADER_ID = 'UT'
    register_map

    ATIME_MASK = 0b010
    CTIME_MASK = 0b100
    MTIME_MASK = 0b001

    def initialize(binstr = nil)
      @ctime = nil
      @mtime = nil
      @atime = nil
      @flag  = 0

      merge(binstr) unless binstr.nil?
    end

    attr_reader :atime, :ctime, :mtime, :flag

    def atime=(time)
      @flag = time.nil? ? @flag & ~ATIME_MASK : @flag | ATIME_MASK
      @atime = time
    end

    def ctime=(time)
      @flag = time.nil? ? @flag & ~CTIME_MASK : @flag | CTIME_MASK
      @ctime = time
    end

    def mtime=(time)
      @flag = time.nil? ? @flag & ~MTIME_MASK : @flag | MTIME_MASK
      @mtime = time
    end

    def merge(binstr)
      return if binstr.empty?

      size, content = initial_parse(binstr)
      return if !size || size <= 0

      @flag, *times = content.unpack('Cl<l<l<')

      # Parse the timestamps, in order, based on which flags are set.
      return if times[0].nil?

      @mtime ||= ::Zip::DOSTime.at(times.shift) unless @flag & MTIME_MASK == 0
      return if times[0].nil?

      @atime ||= ::Zip::DOSTime.at(times.shift) unless @flag & ATIME_MASK == 0
      return if times[0].nil?

      @ctime ||= ::Zip::DOSTime.at(times.shift) unless @flag & CTIME_MASK == 0
    end

    def ==(other)
      @mtime == other.mtime &&
        @atime == other.atime &&
        @ctime == other.ctime
    end

    def pack_for_local
      s = [@flag].pack('C')
      s << [@mtime.to_i].pack('l<') unless @flag & MTIME_MASK == 0
      s << [@atime.to_i].pack('l<') unless @flag & ATIME_MASK == 0
      s << [@ctime.to_i].pack('l<') unless @flag & CTIME_MASK == 0
      s
    end

    def pack_for_c_dir
      s = [@flag].pack('C')
      s << [@mtime.to_i].pack('l<') unless @flag & MTIME_MASK == 0
      s
    end
  end
end

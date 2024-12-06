module Zip
  class ExtraField::Generic
    def self.register_map
      return unless const_defined?(:HEADER_ID)

      ::Zip::ExtraField::ID_MAP[const_get(:HEADER_ID)] = self
    end

    def self.name
      @name ||= to_s.split('::')[-1]
    end

    # return field [size, content] or false
    def initial_parse(binstr)
      return false unless binstr

      if binstr[0, 2] != self.class.const_get(:HEADER_ID)
        warn 'WARNING: weird extra field header ID. Skip parsing it.'
        return false
      end

      [binstr[2, 2].unpack1('v'), binstr[4..-1]]
    end

    def ==(other)
      return false if self.class != other.class

      each do |k, v|
        return false if v != other[k]
      end
      true
    end

    def to_local_bin
      s = pack_for_local
      self.class.const_get(:HEADER_ID) + [s.bytesize].pack('v') << s
    end

    def to_c_dir_bin
      s = pack_for_c_dir
      self.class.const_get(:HEADER_ID) + [s.bytesize].pack('v') << s
    end
  end
end

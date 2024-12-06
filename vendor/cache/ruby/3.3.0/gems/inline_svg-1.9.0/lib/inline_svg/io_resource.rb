module InlineSvg
  module IOResource
    def self.===(object)
      object.is_a?(IO) || object.is_a?(StringIO)
    end

    def self.default_for(object)
      case object
      when StringIO then ''
      when IO then 1
      end
    end

    def self.read(object)
      start = object.pos
      str = object.read
      object.seek start
      str
    end
  end
end

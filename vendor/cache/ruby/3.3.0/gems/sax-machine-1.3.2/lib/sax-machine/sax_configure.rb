module SAXMachine
  def self.configure(clazz)
    extended_clazz = Class.new(clazz)
    extended_clazz.send(:include, SAXMachine)

    # override create_attr to create attributes on the original class
    def extended_clazz.create_attr real_name
      superclass.send(:attr_reader, real_name) unless superclass.method_defined?(real_name)
      superclass.send(:attr_writer, real_name) unless superclass.method_defined?("#{real_name}=")
    end

    yield(extended_clazz)

    clazz.extend LightWeightSaxMachine
    clazz.sax_config = extended_clazz.sax_config

    (class << clazz;self;end).send(:define_method, :parse) do |xml_input|
      extended_clazz.parse(xml_input)
    end
  end

  module LightWeightSaxMachine
    attr_writer :sax_config

    def sax_config
      @sax_config ||= SAXConfig.new
    end

    def inherited(subclass)
      subclass.sax_config.send(:initialize_copy, self.sax_config)
    end
  end
end

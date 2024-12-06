require 'time'

module SAXMachine
  module SAXAbstractHandler
    NO_BUFFER = :no_buffer

    class StackNode < Struct.new(:object, :config, :buffer)
      def initialize(object, config = nil, buffer = NO_BUFFER)
        self.object = object
        self.config = config
        self.buffer = buffer
      end
    end

    def sax_parse(xml_input)
      raise NotImplementedError
    end

    def _initialize(object, on_error = nil, on_warning = nil)
      @stack = [ StackNode.new(object) ]
      @parsed_configs = {}
      @on_error = on_error
      @on_warning = on_warning
    end

    def _characters(data)
      node = stack.last

      if node.buffer == NO_BUFFER
        node.buffer = data.dup
      else
        node.buffer << data
      end
    end

    def _start_element(name, attrs = [])
      name   = normalize_name(name)
      node   = stack.last
      object = node.object

      sax_config = sax_config_for(object)

      if sax_config
        attrs = Hash[attrs]

        if collection_config = sax_config.collection_config(name, attrs)
          object     = collection_config.data_class.new
          sax_config = sax_config_for(object)

          stack.push(StackNode.new(object, collection_config))

          set_attributes_on(object, attrs)
        end

        sax_config.element_configs_for_attribute(name, attrs).each do |ec|
          unless parsed_config?(object, ec)
            object.send(ec.setter, ec.value_from_attrs(attrs))
            mark_as_parsed(object, ec)
          end
        end

        if !collection_config && element_config = sax_config.element_config_for_tag(name, attrs)
          new_object =
            case element_config.data_class.to_s
            when "Integer" then 0
            when "Float"   then 0.0
            when "Symbol"  then nil
            when "Time"    then Time.at(0)
            when ""        then object
            else
              element_config.data_class.new
            end

          stack.push(StackNode.new(new_object, element_config))

          set_attributes_on(new_object, attrs)
        end
      end
    end

    def _end_element(name)
      name = normalize_name(name)

      start_tag = stack[-2]
      close_tag = stack[-1]

      return unless start_tag && close_tag

      object  = start_tag.object
      element = close_tag.object
      config  = close_tag.config
      value   = close_tag.buffer

      return unless config.name == name

      unless parsed_config?(object, config)
        if (element_value_config = element_values_for(config))
          element_value_config.each { |evc| element.send(evc.setter, value) }
        end

        if config.respond_to?(:accessor)
          subconfig = sax_config_for(element)

          if econf = subconfig.element_config_for_tag(name, [])
            element.send(econf.setter, value) unless econf.value_configured?
          end

          object.send(config.accessor) << element
        else
          value = data_class_value(config.data_class, value) || element
          object.send(config.setter, value) if value != NO_BUFFER
          mark_as_parsed(object, config)
        end

        # try to set the ancestor
        if (sax_config = sax_config_for(element))
          sax_config.ancestors.each do |ancestor|
            element.send(ancestor.setter, object)
          end
        end
      end

      stack.pop
    end

    def _error(string)
      if @on_error
        @on_error.call(string)
      end
    end

    def _warning(string)
      if @on_warning
        @on_warning.call(string)
      end
    end

    private

    def mark_as_parsed(object, element_config)
      unless element_config.collection?
        @parsed_configs[[object.object_id, element_config.object_id]] = true
      end
    end

    def parsed_config?(object, element_config)
      @parsed_configs[[object.object_id, element_config.object_id]]
    end

    def sax_config_for(object)
      if object.class.respond_to?(:sax_config)
        object.class.sax_config
      end
    end

    def element_values_for(config)
      if config.data_class.respond_to?(:sax_config)
        config.data_class.sax_config.element_values_for_element
      end
    end

    def normalize_name(name)
      name.to_s.tr("-", "_")
    end

    def set_attributes_on(object, attributes)
      config = sax_config_for(object)

      if config
        config.attribute_configs_for_element(attributes).each do |ac|
          value = data_class_value(ac.data_class, ac.value_from_attrs(attributes))
          object.send(ac.setter, value)
        end
      end
    end

    def data_class_value(data_class, value)
      case data_class.to_s
      when "String"  then value != NO_BUFFER ? value.to_s : value
      when "Integer" then value != NO_BUFFER ? value.to_i : value
      when "Float"   then value != NO_BUFFER ? value.to_s.gsub(",",".").to_f : value
      when "Symbol"  then
        if value != NO_BUFFER
          value.to_s.empty? ? nil : value.to_s.downcase.to_sym
        else
          value
        end
      # Assumes that time elements will be string-based and are not
      # something else, e.g. seconds since epoch
      when "Time"    then value != NO_BUFFER ? Time.parse(value.to_s) : value
      when ""        then value
      end
    end

    def stack
      @stack
    end
  end
end

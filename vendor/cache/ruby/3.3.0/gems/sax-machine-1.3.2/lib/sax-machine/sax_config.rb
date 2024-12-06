require "sax-machine/config/sax_element_value"
require "sax-machine/config/sax_attribute"
require "sax-machine/config/sax_element"
require "sax-machine/config/sax_collection"
require "sax-machine/config/sax_ancestor"

module SAXMachine
  class SAXConfig
    attr_accessor :top_level_elements, :top_level_attributes, :top_level_element_value, :collection_elements, :ancestors

    def initialize
      # Default value is an empty array
      @top_level_elements = Hash.new { |hash, key| hash[key] = [] }
      @top_level_attributes  = []
      @top_level_element_value = []
      @collection_elements = Hash.new { |hash, key| hash[key] = [] }
      @ancestors = []
    end

    def columns
      @top_level_elements.map { |_, ecs| ecs }.flatten
    end

    def initialize_copy(sax_config)
      super

      @top_level_elements = sax_config.top_level_elements.clone
      @top_level_attributes = sax_config.top_level_attributes.clone
      @top_level_element_value = sax_config.top_level_element_value.clone
      @collection_elements = sax_config.collection_elements.clone
      @ancestors = sax_config.ancestors.clone
    end

    def add_top_level_element(name, options)
      @top_level_elements[name.to_s] << ElementConfig.new(name, options)
    end

    def add_top_level_attribute(name, options)
      @top_level_attributes << AttributeConfig.new(options.delete(:name), options)
    end

    def add_top_level_element_value(name, options)
      @top_level_element_value << ElementValueConfig.new(options.delete(:name), options)
    end

    def add_collection_element(name, options)
      @collection_elements[name.to_s] << CollectionConfig.new(name, options)
    end

    def add_ancestor(name, options)
      @ancestors << AncestorConfig.new(name, options)
    end

    def collection_config(name, attrs)
      @collection_elements[name.to_s].detect { |cc| cc.attrs_match?(attrs) }
    end

    def attribute_configs_for_element(attrs)
      @top_level_attributes.select { |aa| aa.attrs_match?(attrs) }
    end

    def element_values_for_element
      @top_level_element_value
    end

    def element_configs_for_attribute(name, attrs)
      return [] unless @top_level_elements.has_key?(name.to_s)

      @top_level_elements[name.to_s].select { |ec| ec.has_value_and_attrs_match?(attrs) }
    end

    def element_config_for_tag(name, attrs)
      return unless @top_level_elements.has_key?(name.to_s)

      @top_level_elements[name.to_s].detect { |ec| ec.attrs_match?(attrs) }
    end
  end
end

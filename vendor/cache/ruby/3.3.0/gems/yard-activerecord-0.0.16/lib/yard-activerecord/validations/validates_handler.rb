require 'active_support/inflector'
require 'active_support/core_ext/array'

module YARD::Handlers::Ruby::ActiveRecord::Validate

  # Links with a value of nil will be link to
  # the Rails Validations guide.
  # Other projects can add to the
  STANDARD_LINKS = [
    :acceptance,
    :validates_associated,
    :confirmation,
    :exclusion,
    :format,
    :inclusion,
    :length,
    :numericality,
    :presence,
    :absence,
    :uniqueness,
    :validates_with,
    :validates_each
  ]

  def self.add_validation_type( type, link )
    @custom_types ||= {}
    @custom_types[type.to_sym] = link
  end

  def self.link_for_validation( type )
    type = type.downcase.to_sym
    if STANDARD_LINKS.include?( type )
      "http://edgeguides.rubyonrails.org/active_record_validations.html##{type}"
    elsif @custom_types && link = @custom_types[ type ]
      link
    else
      nil
    end
  end

  # Define validations tag for later use
  YARD::Tags::Library.define_tag("Validations", :validates )

  # Document ActiveRecord validations.
  # This handler handles the validates statement.
  # It will parse the list of fields, the validation types and their options,
  # and the optional :if/:unless clause.
  # It only handles the newer Rails ":validates" syntax and does not
  # recognize the older "validates_presence_of" type methods.
  class ValidatesHandler < YARD::Handlers::Ruby::MethodHandler
    namespace_only
    handles method_call(:validates)
    def process

      validations = {}
      attributes  = []
      conditions  = {}

      # Read each parameter to the statement and parse out
      # it's type and intent
      statement.parameters(false).compact.map do |param|
        # list types are options
        if param.type == :list
          param.each do | n |
            kw = n.jump(:label, :symbol_literal ).source.gsub(/:/,'')
            # if/unless are conditions that apply to all the validations
            if ['if','unless','on'].include?(kw)
              conditions[ kw ] = n.children.last.source
            else # otherwise it's type specific
              opts = n.jump(:hash)
              value = ( opts != n ) ? opts.source : nil
              validations[ kw ] = value
            end
          end
        elsif param.type == :symbol_literal
          attributes << param.jump(:ident, :kw, :tstring_content).source
        end
      end

      # abort in case we didn't parse anything
      return if validations.empty?

      # Loop through each attribute and set a tag on each
      attributes.each do | attribute |
        method_definition = namespace.instance_attributes[attribute.to_sym] || {}
        method = method_definition[:read]
        if ! method
          meths = namespace.meths(:all => true)
          method = meths.find {|m| m.name == attribute.to_sym }
        end
        # If the method isn't defined yet, go ahead and create one
        if ! method
          method = register YARD::CodeObjects::MethodObject.new(namespace, attribute )
          method.scope = :instance
          method.explicit = false
          method_definition[:read] = method
          namespace.instance_attributes[attribute.to_sym] = method_definition
        end
        tag = YARD::Tags::OptionTag.new(:validates, '', conditions ) #, [] )
        tag.types = {} #[]
        validations.each{ |arg,options|
          tag.types[ arg ] = options
        }
        method.docstring.add_tag tag
      end

    end
  end

end

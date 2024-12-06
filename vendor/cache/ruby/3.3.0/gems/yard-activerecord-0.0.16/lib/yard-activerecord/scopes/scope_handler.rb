require 'active_support/inflector'

module YARD::Handlers::Ruby::ActiveRecord::Scopes
  class ScopeHandler < YARD::Handlers::Ruby::MethodHandler
    handles method_call(:scope)
    namespace_only
    
    def process
      object = register YARD::CodeObjects::MethodObject.new(namespace, method_name, :class)
      object.docstring = return_description
      object.docstring.add_tag get_tag(:return, '', class_name)
      object.docstring.add_tag get_tag(:see,"ActiveRecord::Scoping", nil,
        'http://api.rubyonrails.org/classes/ActiveRecord/Scoping/Named/ClassMethods.html')
    end
    
    private
    def method_name
      call_params[0]
    end
    
    def return_description
      "A relation of #{ActiveSupport::Inflector.pluralize namespace.to_s} " +
      "that are #{method_name.split('_').join(' ')}. " +
      "<strong>Active Record Scope</strong>"
    end
    
    def class_name
      "ActiveRecord::Relation<#{namespace}>"
    end

    def get_tag(tag, text, return_classes = [],name=nil)
      YARD::Tags::Tag.new(tag, text, [return_classes].flatten,name)
    end
  end
end

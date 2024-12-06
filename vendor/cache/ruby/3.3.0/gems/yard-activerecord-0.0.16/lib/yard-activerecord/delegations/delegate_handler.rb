require 'yard'

module YARD::Handlers::Ruby::ActiveRecord::Delegations
  class DelegateHandler < YARD::Handlers::Ruby::MethodHandler
    handles method_call(:delegate)
    namespace_only

    def process
      params = statement.parameters
      params.pop # we shouldn't have a block, so pop that off
      params.map! { |p| p.source.split(",") }
      params.flatten!
      options, params = params.partition { |v| v =~ /\=\>|\:\s/ }
      if options.length > 0
        class_name = options.detect { |v| v =~ /to\:\s|\:to\s+\=\>/ }
        class_name = class_name.to_s.gsub(/\A.*\:/,'').capitalize
        prefix_name = options.detect { |v| v =~ /prefix\:\s|\:prefix\s+\=\>/ }
        prefix_name = prefix_name.to_s.gsub(/\A.*\:/,'').strip
      end

      params.each do |method_name|
        method_name.gsub!(/[\:\'\"]/,'')
        original_method_name = method_name.dup

        unless prefix_name.length == 0
          prefix_name = class_name.downcase if prefix_name == 'true'
          method_name.prepend("#{prefix_name}_")
        end
        object = register YARD::CodeObjects::MethodObject.new(namespace, method_name)
        object.group = "Delegated Instance Attributes"
        object.docstring = "Alias for #{class_name}##{original_method_name}"
        object.docstring.add_tag get_tag(:return,
            "#{class_name}##{method_name}", 'Object')
        object.docstring.add_tag get_tag(:see,"Module#delegate",nil,
            "http://api.rubyonrails.org/classes/Module.html#method-i-delegate")
      end
      group_name = "Delegated Instance Attributes"
      namespace.groups << group_name unless namespace.groups.include? group_name
    end

    private

    def get_tag(tag, text, return_classes = [], name=nil)
      YARD::Tags::Tag.new(tag, text, [return_classes].flatten,name)
    end
  end
end

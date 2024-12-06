require "rolify/configure"

module Rolify
  module Dynamic
    def define_dynamic_method(role_name, resource)
      class_eval do 
        define_method("is_#{role_name}?".to_sym) do
          has_role?("#{role_name}")
        end if !method_defined?("is_#{role_name}?".to_sym) && self.adapter.where_strict(self.role_class, name: role_name).exists?

        define_method("is_#{role_name}_of?".to_sym) do |arg|
          has_role?("#{role_name}", arg)
        end if !method_defined?("is_#{role_name}_of?".to_sym) && resource && self.adapter.where_strict(self.role_class, name: role_name, resource: resource).exists?
      end
    end
  end
end

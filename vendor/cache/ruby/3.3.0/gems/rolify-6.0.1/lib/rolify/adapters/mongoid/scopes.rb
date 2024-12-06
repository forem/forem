module Rolify
  module Adapter
    module Scopes
      def global
        where(:resource_type => nil, :resource_id => nil)
      end
      
      def class_scoped(resource_type = nil)
        where_conditions = { :resource_type.ne => nil, :resource_id => nil }
        where_conditions = { :resource_type => resource_type.name, :resource_id => nil } if resource_type
        where(where_conditions)
      end
      
      def instance_scoped(resource_type = nil)
        where_conditions = { :resource_type.ne => nil, :resource_id.ne => nil }
        if resource_type
          if resource_type.is_a? Class
            where_conditions = { :resource_type => resource_type.name, :resource_id.ne => nil }
          else
            where_conditions = { :resource_type => resource_type.class.name, :resource_id => resource_type.id }
          end
        end
        where(where_conditions)
      end
    end
  end
end
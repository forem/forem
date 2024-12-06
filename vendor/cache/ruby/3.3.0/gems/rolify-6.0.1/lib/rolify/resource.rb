module Rolify
  module Resource
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def find_roles(role_name = nil, user = nil)
        self.resource_adapter.find_roles(role_name, self, user)
      end

      def with_role(role_name, user = nil)
        if role_name.is_a? Array
          role_name = role_name.map(&:to_s)
        else
          role_name = role_name.to_s
        end

        resources = self.resource_adapter.resources_find(self.role_table_name, self, role_name) #.map(&:id)
        user ? self.resource_adapter.in(resources, user, role_name) : resources
      end
      alias :with_roles :with_role
      alias :find_as :with_role 
      alias :find_multiple_as :with_role


      def without_role(role_name, user = nil)
        self.resource_adapter.all_except(self, self.find_as(role_name, user))
      end
      alias :without_roles :without_role
      alias :except_as :without_role 
      alias :except_multiple_as :without_role 



      def applied_roles(children = true)
        self.resource_adapter.applied_roles(self, children)
      end


      
    end

    def applied_roles
      #self.roles + self.class.role_class.where(:resource_type => self.class.to_s, :resource_id => nil)
      self.roles + self.class.applied_roles(true)
    end
  end
end

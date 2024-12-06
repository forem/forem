require 'rolify/adapters/base'

module Rolify
  module Adapter
    class ResourceAdapter < ResourceAdapterBase

      def find_roles(role_name, relation, user)
        roles = user && (user != :any) ? user.roles : self.role_class
        roles = roles.where(:resource_type.in => self.relation_types_for(relation))
        roles = roles.where(:name => role_name.to_s) if role_name && (role_name != :any)
        roles
      end

      def resources_find(roles_table, relation, role_name)
        roles = roles_table.classify.constantize.where(:name.in => Array(role_name), :resource_type.in => self.relation_types_for(relation))
        resources = []
        roles.each do |role|
          if role.resource_id.nil?
            resources += relation.all
          else
            resources << role.resource
          end
        end
        resources.compact.uniq
      end

      def in(resources, user, role_names)
        roles = user.roles.where(:name.in => Array(role_names))
        return [] if resources.empty? || roles.empty?
        resources.delete_if { |resource| (resource.applied_roles & roles).empty? }
        resources
      end

      def applied_roles(relation, children)
        if children
          relation.role_class.where(:resource_type.in => self.relation_types_for(relation), :resource_id => nil)
        else
          relation.role_class.where(:resource_type => relation.to_s, :resource_id => nil)
        end
      end

      def all_except(resource, excluded_obj)
        resource.not_in(_id: excluded_obj.to_a)
      end

    end
  end
end
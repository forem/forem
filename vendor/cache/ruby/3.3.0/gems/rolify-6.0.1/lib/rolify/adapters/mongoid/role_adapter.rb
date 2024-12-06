require 'rolify/adapters/base'

module Rolify
  module Adapter
    class RoleAdapter < RoleAdapterBase
      def where(relation, *args)
        conditions = build_conditions(relation, args)
        relation.any_of(*conditions)
      end

      def where_strict(relation, args)
        wrap_conditions = relation.name != role_class.name

        conditions = if args[:resource].is_a?(Class)
                       {:resource_type => args[:resource].to_s, :resource_id => nil }
                     elsif args[:resource].present?
                       {:resource_type => args[:resource].class.name, :resource_id => args[:resource].id}
                     else
                       {}
                     end

        conditions.merge!(:name => args[:name])
        conditions = wrap_conditions ? { role_table => conditions } : conditions

        relation.where(conditions)
      end

      def find_cached(relation, args)
        resource_id = (args[:resource].nil? || args[:resource].is_a?(Class) || args[:resource] == :any) ? nil : args[:resource].id
        resource_type = args[:resource].is_a?(Class) ? args[:resource].to_s : args[:resource].class.name

        return relation.find_all { |role| role.name == args[:name].to_s } if args[:resource] == :any

        relation.find_all do |role|
          (role.name == args[:name].to_s && role.resource_type == nil && role.resource_id == nil) ||
          (role.name == args[:name].to_s && role.resource_type == resource_type && role.resource_id == nil) ||
          (role.name == args[:name].to_s && role.resource_type == resource_type && role.resource_id == resource_id)
        end
      end

      def find_cached_strict(relation, args)
        resource_id = (args[:resource].nil? || args[:resource].is_a?(Class)) ? nil : args[:resource].id
        resource_type = args[:resource].is_a?(Class) ? args[:resource].to_s : args[:resource].class.name

        relation.find_all do |role|
          role.resource_id == resource_id && role.resource_type == resource_type && role.name == args[:name].to_s
        end
      end

      def find_or_create_by(role_name, resource_type = nil, resource_id = nil)
        self.role_class.find_or_create_by(:name => role_name,
                                          :resource_type => resource_type,
                                          :resource_id => resource_id)
      end

      def add(relation, role)
        relation.roles << role
      end

      def remove(relation, role_name, resource = nil)
        #roles = { :name => role_name }
        #roles.merge!({:resource_type => (resource.is_a?(Class) ? resource.to_s : resource.class.name)}) if resource
        #roles.merge!({ :resource_id => resource.id }) if resource && !resource.is_a?(Class)
        #roles_to_remove = relation.roles.where(roles)
        #roles_to_remove.each do |role|
        #  # Deletion in n-n relations is unreliable. Sometimes it works, sometimes not.
        #  # So, this does not work all the time: `relation.roles.delete(role)`
        #  # @see http://stackoverflow.com/questions/9132596/rails3-mongoid-many-to-many-relation-and-delete-operation
        #  # We instead remove ids from the Role object and the relation object.
        #  relation.role_ids.delete(role.id)
        #  role.send((user_class.to_s.underscore + '_ids').to_sym).delete(relation.id)
        #
        #  role.destroy if role.send(user_class.to_s.tableize.to_sym).empty?
        #end
        cond = { :name => role_name }
        cond[:resource_type] = (resource.is_a?(Class) ? resource.to_s : resource.class.name) if resource
        cond[:resource_id] = resource.id if resource && !resource.is_a?(Class)
        roles = relation.roles.where(cond)
        roles.each do |role|
          relation.roles.delete(role)
          role.send(ActiveSupport::Inflector.demodulize(user_class).tableize.to_sym).delete(relation)
          if Rolify.remove_role_if_empty && role.send(ActiveSupport::Inflector.demodulize(user_class).tableize.to_sym).empty?
            role.destroy
          end
        end if roles
        roles
      end

      def exists?(relation, column)
        relation.where(column.to_sym.ne => nil)
      end

      def scope(relation, conditions, strict)
        query = strict ? where_strict(role_class, conditions) : where(role_class, conditions)
        roles = query.map { |role| role.id }
        return [] if roles.size.zero?
        query = relation.any_in(:role_ids => roles)
        query
      end

      def all_except(user, excluded_obj)
        user.not_in(_id: excluded_obj.to_a)
      end

      private

      def build_conditions(relation, args)
        conditions = []
        args.each do |arg|
          if arg.is_a? Hash
            query = build_query(arg[:name], arg[:resource])
          elsif arg.is_a?(String) || arg.is_a?(Symbol)
            query = build_query(arg)
          else
            raise ArgumentError, "Invalid argument type: only hash or string or symbol allowed"
          end
          conditions += query
        end
        conditions
      end

      def build_query(role, resource = nil)
        return [{ :name => role }] if resource == :any
        query = [{ :name => role, :resource_type => nil, :resource_id => nil }]
        if resource
          query << { :name => role, :resource_type => (resource.is_a?(Class) ? resource.to_s : resource.class.name), :resource_id => nil }
          if !resource.is_a? Class
            query << { :name => role, :resource_type => resource.class.name, :resource_id => resource.id }
          end
        end
        query
      end
    end
  end
end

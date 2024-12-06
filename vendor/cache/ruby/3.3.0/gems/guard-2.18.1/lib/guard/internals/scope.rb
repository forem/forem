require "guard"

module Guard
  # @private api
  module Internals
    class Scope
      def initialize
        @interactor_plugin_scope = []
        @interactor_group_scope = []
      end

      def to_hash
        {
          plugins: _hashify_scope(:plugin),
          groups: _hashify_scope(:group)
        }.dup.freeze
      end

      # TODO: refactor
      def grouped_plugins(scope = { plugins: [], groups: [] })
        items = nil
        plugins = _find_non_empty_scope(:plugins, scope)
        if plugins
          items = Array(plugins).map { |plugin| _instantiate(:plugin, plugin) }
        end

        unless items
          # TODO: no coverage here!!
          found = _find_non_empty_scope(:groups, scope)
          found ||= Guard.state.session.groups.all
          groups = Array(found).map { |group| _instantiate(:group, group) }
          if groups.any? { |g| g.name == :common }
            items = groups
          else
            items = ([_instantiate(:group, :common)] + Array(found)).compact
          end
        end

        items.map do |plugin_or_group|
          group = nil
          plugins = [plugin_or_group]
          if plugin_or_group.is_a?(Group)
            # TODO: no coverage here!
            group = plugin_or_group
            plugins = Guard.state.session.plugins.all(group: group.name)
          end
          [group, plugins]
        end
      end

      def from_interactor(scope)
        @interactor_plugin_scope = Array(scope[:plugins])
        @interactor_group_scope = Array(scope[:groups])
      end

      def titles(scope = nil)
        hash = scope || to_hash
        plugins = hash[:plugins]
        groups = hash[:groups]
        return plugins.map(&:title) unless plugins.nil? || plugins.empty?
        return hash[:groups].map(&:title) unless groups.nil? || groups.empty?
        ["all"]
      end

      private

      # TODO: move to session
      def _scope_names(new_scope, name)
        items = Array(new_scope[:"#{name}s"] || new_scope[name]) if items.empty?

        # Convert objects to names
        items.map { |p| p.respond_to?(:name) ? p.name : p }
      end

      # TODO: let the Plugins and Groups classes handle this?
      # TODO: why even instantiate?? just to check if it exists?
      def _hashify_scope(type)
        # TODO: get cmdline passed to initialize above?
        cmdline = Array(Guard.state.session.send("cmdline_#{type}s"))
        guardfile = Guard.state.session.send(:"guardfile_#{type}_scope")
        interactor = instance_variable_get(:"@interactor_#{type}_scope")

        # TODO: session should decide whether to use cmdline or guardfile -
        # since it has access to both variables
        items = [interactor, cmdline, guardfile].detect do |source|
          !source.empty?
        end

        # TODO: not tested when groups/plugins given don't exist

        # TODO: should already be instantiated
        Array(items).map do |obj|
          if obj.respond_to?(:name)
            obj
          else
            name = obj
            (type == :group ? _groups : _plugins).all(name).first
          end
        end.compact
      end

      def _instantiate(meth, obj)
        # TODO: no coverage
        return obj unless obj.is_a?(Symbol) || obj.is_a?(String)
        Guard.state.session.send("#{meth}s".to_sym).all(obj).first
      end

      def _find_non_empty_scope(type, local_scope)
        [Array(local_scope[type]), to_hash[type]].map(&:compact).detect(&:any?)
      end

      def _groups
        Guard.state.session.groups
      end

      def _plugins
        Guard.state.session.plugins
      end
    end
  end
end

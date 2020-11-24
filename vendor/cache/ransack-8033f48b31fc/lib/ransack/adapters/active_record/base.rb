module Ransack
  module Adapters
    module ActiveRecord
      module Base

        def self.extended(base)
          alias :search :ransack unless base.respond_to? :search
          base.class_eval do
            class_attribute :_ransackers
            class_attribute :_ransack_aliases
            self._ransackers ||= {}
            self._ransack_aliases ||= {}
          end
        end

        def ransack(params = {}, options = {})
          ActiveSupport::Deprecation.warn("#search is deprecated and will be removed in 2.3, please use #ransack instead") if __callee__ == :search
          Search.new(self, params, options)
        end

        def ransacker(name, opts = {}, &block)
          self._ransackers = _ransackers.merge name.to_s => Ransacker
            .new(self, name, opts, &block)
        end

        def ransack_alias(new_name, old_name)
          self._ransack_aliases = _ransack_aliases.merge new_name.to_s =>
            old_name.to_s
        end

        # Ransackable_attributes, by default, returns all column names
        # and any defined ransackers as an array of strings.
        # For overriding with a whitelist array of strings.
        #
        def ransackable_attributes(auth_object = nil)
          @ransackable_attributes ||= if Ransack::SUPPORTS_ATTRIBUTE_ALIAS
            column_names + _ransackers.keys + _ransack_aliases.keys +
            attribute_aliases.keys
          else
            column_names + _ransackers.keys + _ransack_aliases.keys
          end
        end

        # Ransackable_associations, by default, returns the names
        # of all associations as an array of strings.
        # For overriding with a whitelist array of strings.
        #
        def ransackable_associations(auth_object = nil)
          @ransackable_associations ||= reflect_on_all_associations.map { |a| a.name.to_s }
        end

        # Ransortable_attributes, by default, returns the names
        # of all attributes available for sorting as an array of strings.
        # For overriding with a whitelist array of strings.
        #
        def ransortable_attributes(auth_object = nil)
          ransackable_attributes(auth_object)
        end

        # Ransackable_scopes, by default, returns an empty array
        # i.e. no class methods/scopes are authorized.
        # For overriding with a whitelist array of *symbols*.
        #
        def ransackable_scopes(auth_object = nil)
          []
        end

        # ransack_scope_skip_sanitize_args, by default, returns an empty array.
        # i.e. use the sanitize_scope_args setting to determin if args should be converted.
        # For overriding with a list of scopes which should be passed the args as-is.
        #
        def ransackable_scopes_skip_sanitize_args
          []
        end

      end
    end
  end
end

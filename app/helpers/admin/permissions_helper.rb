module Admin
  module PermissionsHelper
    PLATFORM_ROLE_OPTIONS = [
      ["Super Admin", "super_admin"],
      ["Admin", "admin"],
      ["Tech Admin", "tech_admin"],
    ].freeze

    def grantable_role_options_grouped(is_super_admin:, include_configurable_hint: true)
      resource_options = Constants::Role::SPECIAL_ROLES_LABELS_TO_WHERE_CLAUSE.filter_map do |_label, config|
        next unless config[:name] == SubPermissions::ROLE_NAME && config[:resource_type].present?

        resource_type = config[:resource_type]
        next if !is_super_admin && Constants::Role::SUPER_ADMIN_ONLY_RESOURCE_TYPES.include?(resource_type)

        display_label = "#{resource_type} Admin"
        if include_configurable_hint && SubPermissions.configurable?(resource_type)
          display_label = "#{display_label} #{t('views.admin.permissions.grant.configurable_suffix')}"
        end

        [display_label, "#{SubPermissions::ROLE_NAME}|#{resource_type}"]
      end.sort_by(&:first)

      groups = []
      groups << [t("views.admin.permissions.grant.platform_group"), PLATFORM_ROLE_OPTIONS] if is_super_admin
      groups << [t("views.admin.permissions.grant.resource_group"), resource_options]
      groups
    end

    def assignable_role_options_for_user(user, is_super_admin:)
      held_values = user_held_role_values(user)
      grantable_role_options_grouped(is_super_admin: is_super_admin,
                                     include_configurable_hint: false).filter_map do |group, options|
        remaining = options.reject { |_label, value| held_values.include?(value) }
        [group, remaining] if remaining.any?
      end
    end

    def user_admin_roles(user, sub_permissions, is_super_admin:)
      roles = []
      fetched_roles = user.roles.to_a

      PLATFORM_ROLE_OPTIONS.each do |label, name|
        next unless fetched_roles.any? { |r| r.name == name && r.resource_type.nil? && r.resource_id.nil? }

        roles << {
          label: label,
          base_label: label,
          value: name,
          tier: name.to_sym,
          resource_type: nil,
          configurable: false,
          stored_config: nil,
          restricted: false,
          can_revoke: is_super_admin
        }
      end

      resource_types = fetched_roles
        .filter_map { |r| r.resource_type if r.name == SubPermissions::ROLE_NAME && r.resource_type.present? }
        .uniq
        .sort

      resource_types.each do |resource_type|
        class_wide = fetched_roles.any? do |r|
          r.name == SubPermissions::ROLE_NAME && r.resource_type == resource_type && r.resource_id.nil?
        end
        roles << build_resource_role_entry(
          user,
          resource_type,
          sub_permissions,
          is_super_admin: is_super_admin,
          class_wide: class_wide,
        )
      end

      roles
    end

    def user_global_override_label(admin_roles)
      return "Super Admin" if admin_roles.any? { |r| r[:tier] == :super_admin }
      return "Admin" if admin_roles.any? { |r| r[:tier] == :admin }

      nil
    end

    def sub_permissions_ui_config
      SubPermissions::CLAUSES.each_with_object({}) do |(resource_type, clauses), hash|
        hash[resource_type] = {
          resource_type: resource_type,
          title: "#{resource_type} #{t('lib.sub_permissions.admin.summary')}",
          baseline_hint: SubPermissions.baseline_hint(resource_type),
          clauses: clauses.map do |clause|
            {
              key: clause,
              label: SubPermissions.clause_label(resource_type, clause).upcase_first,
              description: SubPermissions.clause_description(resource_type, clause)
            }
          end
        }
      end
    end

    def permissions_filter_tabs(role_counts)
      [
        { key: "", label: t("views.admin.permissions.filters.all"), count: role_counts[:all] },
        { key: "super_admin", label: t("views.admin.permissions.filters.super_admin"),
          count: role_counts[:super_admin] },
        { key: "admin", label: t("views.admin.permissions.filters.admin"), count: role_counts[:admin] },
        { key: "tech_admin", label: t("views.admin.permissions.filters.tech_admin"), count: role_counts[:tech_admin] },
        { key: "single_resource_admin", label: t("views.admin.permissions.filters.single_resource_admin"),
          count: role_counts[:single_resource_admin] },
        { key: "restricted", label: t("views.admin.permissions.filters.restricted"), count: role_counts[:restricted],
          restricted: true },
      ]
    end

    def permissions_return_filter_fields(search:, role_filter:, resource_filter:)
      safe_join(
        [
          (hidden_field_tag(:return_search, search) if search.present?),
          (hidden_field_tag(:return_role_filter, role_filter) if role_filter.present?),
          (hidden_field_tag(:return_resource_filter, resource_filter) if resource_filter.present?),
        ].compact,
      )
    end

    private

    def user_held_role_values(user)
      user.roles.each_with_object(Set.new) do |role, values|
        if role.name == SubPermissions::ROLE_NAME && role.resource_type.present?
          values << "#{SubPermissions::ROLE_NAME}|#{role.resource_type}"
        elsif role.resource_type.nil? && role.resource_id.nil?
          values << role.name
        end
      end
    end

    def build_resource_role_entry(user, resource_type, sub_permissions, is_super_admin:, class_wide:)
      restricted = class_wide && sub_permissions.key?([user.id, resource_type])
      stored_config = restricted ? sub_permissions[[user.id, resource_type]] : nil
      base_label = "#{resource_type} Admin"
      label = restricted ? "#{base_label} (#{t('lib.sub_permissions.admin.restricted')})" : base_label
      super_admin_only = Constants::Role::SUPER_ADMIN_ONLY_RESOURCE_TYPES.include?(resource_type)

      {
        label: label,
        base_label: base_label,
        value: "#{SubPermissions::ROLE_NAME}|#{resource_type}",
        tier: :resource,
        resource_type: resource_type,
        configurable: class_wide && SubPermissions.configurable?(resource_type),
        stored_config: stored_config,
        restricted: restricted,
        can_revoke: is_super_admin || !super_admin_only
      }
    end
  end
end

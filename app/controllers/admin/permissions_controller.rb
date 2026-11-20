module Admin
  class PermissionsController < Admin::ApplicationController
    layout "admin"

    SUPER_ADMIN_ONLY_RESOURCES = Constants::Role::SUPER_ADMIN_ONLY_RESOURCE_TYPES
    GLOBAL_ADMIN_ROLE_NAMES = %w[admin super_admin tech_admin].freeze
    VALID_ROLE_FILTERS = %w[super_admin admin tech_admin single_resource_admin restricted].freeze

    def index
      roles = admin_roles
      @search = params[:search].to_s.strip
      @role_filter = VALID_ROLE_FILTERS.include?(params[:role_filter].to_s) ? params[:role_filter].to_s : ""
      @resource_filter = params[:resource_filter].to_s.strip
      @filters_active = @search.present? || @role_filter.present? || @resource_filter.present?
      @available_resource_types = roles
        .filter_map { |r| r.resource_type if r.name == SubPermissions::ROLE_NAME && r.resource_type.present? }
        .uniq
        .sort
      @role_counts = compute_role_counts(roles)

      @users = filtered_users(roles)
      @is_super_admin = current_user_super_admin?(roles, @users)
      @sub_permissions = restricted_grants(@users.map(&:id))
    end

    def grant
      user = User.find_by(username: params[:username].to_s.delete("@").strip)
      role_name, resource_type = params[:role_name].to_s.split("|", 2)
      resource_class = resolve_resource_class(resource_type)
      return refuse_super_admin_only unless assignable?(role_name, resource_type, resource_class)

      if params[:restricted] == "1" && role_name == SubPermissions::ROLE_NAME
        grant_restricted_role(user: user, resource_class: resource_class)
      else
        mutate_role(user: user, mutation: :add_role, success_verb: "Granted", preposition: "to")
      end
    end

    def revoke
      user = User.find_by(id: params[:user_id])
      mutate_role(user: user, mutation: :remove_role, success_verb: "Revoked", preposition: "from")
    end

    def sub_permissions
      user = User.find_by(id: params[:user_id])
      role_name, resource_type = params[:role_name].to_s.split("|", 2)
      resource_class = resolve_resource_class(resource_type)
      return refuse_super_admin_only unless assignable?(role_name, resource_type, resource_class)

      unless user && role_name == SubPermissions::ROLE_NAME && resource_class
        flash[:error] = "Invalid user or role" # rubocop:disable Rails/I18nLocaleTexts
        return redirect_to permissions_redirect_path, status: :see_other
      end

      unless %w[0 1].include?(params[:restricted])
        flash[:error] = I18n.t("lib.sub_permissions.errors.mode_required")
        return redirect_to permissions_redirect_path, status: :see_other
      end

      config = build_sub_permissions_config
      result = SubPermissions.update_grant(user: user, resource_type: resource_class.name, sub_permissions: config)

      if result.success?
        log_sub_permissions_update(user: user, resource_type: resource_class.name, config: config)
        flash[:success] = I18n.t("lib.sub_permissions.admin.updated",
                                 resource: resource_class.name, username: user.username)
      else
        flash[:error] = result.errors.to_sentence
      end

      redirect_to permissions_redirect_path, status: :see_other
    end

    private

    def grant_restricted_role(user:, resource_class:)
      unless user && valid_role_target?(SubPermissions::ROLE_NAME, resource_class)
        flash[:error] = "Invalid user or role" # rubocop:disable Rails/I18nLocaleTexts
        return redirect_to permissions_redirect_path, status: :see_other
      end

      config = SubPermissions.build(allow: allow_param)
      validation = SubPermissions::Config.new(config, resource_type: resource_class.name)
      unless validation.valid?
        flash[:error] = validation.errors.to_sentence
        return redirect_to permissions_redirect_path, status: :see_other
      end

      result = nil
      ActiveRecord::Base.transaction do
        user.add_role(SubPermissions::ROLE_NAME, resource_class)
        result = SubPermissions.update_grant(user: user, resource_type: resource_class.name, sub_permissions: config)
        raise ActiveRecord::Rollback unless result.success?
      end

      if result&.success?
        log_sub_permissions_update(user: user, resource_type: resource_class.name, config: config)
        flash[:success] = I18n.t("lib.sub_permissions.admin.granted_restricted",
                                 resource: resource_class.name, username: user.username)
      else
        flash[:error] = result&.errors&.to_sentence.presence || "Invalid user or role"
      end

      redirect_to permissions_redirect_path, status: :see_other
    end

    def mutate_role(user:, mutation:, success_verb:, preposition:)
      role_name, resource_type = params[:role_name].to_s.split("|", 2)
      resource_class = resolve_resource_class(resource_type)
      return refuse_super_admin_only unless assignable?(role_name, resource_type, resource_class)

      if user && valid_role_target?(role_name, resource_class)
        if role_name == SubPermissions::ROLE_NAME
          user.public_send(mutation, role_name, resource_class)
        else
          user.public_send(mutation, role_name)
        end
        log_role_change(user: user, mutation: mutation, role_name: role_name, resource_class: resource_class)
        flash[:success] = "#{success_verb} #{params[:role_name]} #{preposition} #{user.username}"
      else
        flash[:error] = "Invalid user or role" # rubocop:disable Rails/I18nLocaleTexts
      end

      redirect_to permissions_redirect_path, status: :see_other
    end

    def allow_param
      params[:allow].is_a?(Array) ? params[:allow] : []
    end

    def build_sub_permissions_config
      params[:restricted] == "1" ? SubPermissions.build(allow: allow_param) : nil
    end

    def log_role_change(user:, mutation:, role_name:, resource_class:)
      audit_payload = {
        "action" => mutation == :add_role ? "grant_role" : "revoke_role",
        "target_user_id" => user.id,
        "role_name" => role_name,
        "resource_type" => resource_class&.name
      }
      Audit::Logger.log(:internal, current_user, audit_payload)
    end

    def log_sub_permissions_update(user:, resource_type:, config:)
      audit_payload = {
        "action" => "update_sub_permissions",
        "target_user_id" => user.id,
        "resource_type" => resource_type,
        "sub_permissions" => config
      }
      Audit::Logger.log(:internal, current_user, audit_payload)
    end

    def resolve_resource_class(resource_type)
      return if resource_type.blank?

      constant = resource_type.strip.safe_constantize
      constant if constant.is_a?(Class)
    end

    def valid_role_target?(role_name, resource_class)
      return false unless %w[admin super_admin tech_admin single_resource_admin].include?(role_name)
      return true unless role_name == SubPermissions::ROLE_NAME

      resource_class.present? && Rolify.resource_types.include?(resource_class.name)
    end

    def assignable?(role_name, resource_type, resource_class)
      return current_user.super_admin? if GLOBAL_ADMIN_ROLE_NAMES.include?(role_name)
      return true unless role_name == SubPermissions::ROLE_NAME
      return current_user.super_admin? if resource_type.blank?

      resolved_name = resource_class&.name || resource_type.to_s.strip.delete_prefix("::")
      return true unless SUPER_ADMIN_ONLY_RESOURCES.include?(resolved_name)

      current_user.super_admin?
    end

    def refuse_super_admin_only
      flash[:error] = "Only super admins can grant or revoke #{params[:role_name]}"
      redirect_to permissions_redirect_path, status: :see_other
    end

    def permissions_redirect_path
      query = {
        search: params[:return_search].presence,
        role_filter: params[:return_role_filter].presence,
        resource_filter: params[:return_resource_filter].presence
      }.compact
      query.empty? ? admin_permissions_path : admin_permissions_path(query)
    end

    def restricted_grants(user_ids)
      return {} if user_ids.empty?

      UserRole.joins(:role)
        .where(user_id: user_ids)
        .where(roles: { name: SubPermissions::ROLE_NAME, resource_type: SubPermissions::CLAUSES.keys })
        .where(roles: { resource_id: nil })
        .where.not(sub_permissions: nil)
        .pluck(:user_id, "roles.resource_type", :sub_permissions)
        .to_h { |user_id, resource_type, config| [[user_id, resource_type], config] }
    end

    def admin_roles
      Role.where(name: GLOBAL_ADMIN_ROLE_NAMES, resource_type: nil, resource_id: nil)
        .or(Role.where(name: SubPermissions::ROLE_NAME))
        .select(:id, :name, :resource_type, :resource_id)
        .to_a
    end

    def current_user_super_admin?(roles, users)
      super_admin_role_id = roles.detect { |r| r.name == "super_admin" && r.resource_type.nil? }&.id
      return false if super_admin_role_id.nil?

      loaded_current_user = users.detect { |u| u.id == current_user.id }
      return loaded_current_user.roles.any? { |r| r.id == super_admin_role_id } if loaded_current_user

      UserRole.exists?(user_id: current_user.id, role_id: super_admin_role_id)
    end

    def filtered_users(roles)
      user_ids_relation = filtered_user_ids_relation(roles)
      return User.none.page(params[:page]).per(50) if user_ids_relation.nil?

      scope = User.where(id: user_ids_relation)
      if @search.present?
        term = "%#{ActiveRecord::Base.sanitize_sql_like(@search.delete_prefix('@'))}%"
        scope = scope.where("users.username ILIKE :term OR users.name ILIKE :term", term: term)
      end

      scope
        .select(:id, :name, :username, :profile_image)
        .preload(:roles)
        .order(:id)
        .page(params[:page])
        .per(50)
    end

    def filtered_user_ids_relation(roles)
      return if roles.empty?

      if @role_filter == "restricted"
        ids = configurable_role_ids(roles)
        return if ids.empty?

        return UserRole.where(role_id: ids).where.not(sub_permissions: nil).select(:user_id)
      end

      ids = matching_role_ids(roles)
      return if ids.empty?

      UserRole.where(role_id: ids).select(:user_id)
    end

    def matching_role_ids(roles)
      if resource_filter_active?
        return roles.filter_map do |r|
          r.id if r.name == SubPermissions::ROLE_NAME && r.resource_type == @resource_filter
        end
      end

      return role_ids_for_global(roles, @role_filter) if GLOBAL_ADMIN_ROLE_NAMES.include?(@role_filter)
      return resource_role_ids(roles) if @role_filter == SubPermissions::ROLE_NAME

      roles.map(&:id)
    end

    def resource_filter_active?
      @resource_filter.present? && (@role_filter.blank? || @role_filter == SubPermissions::ROLE_NAME)
    end

    def role_ids_for_global(roles, role_name)
      roles.filter_map { |r| r.id if r.name == role_name && r.resource_type.nil? }
    end

    def resource_role_ids(roles)
      roles.filter_map { |r| r.id if r.name == SubPermissions::ROLE_NAME }
    end

    def configurable_role_ids(roles)
      roles.filter_map do |r|
        r.id if r.name == SubPermissions::ROLE_NAME &&
          r.resource_id.nil? &&
          SubPermissions::CLAUSES.key?(r.resource_type)
      end
    end

    def compute_role_counts(roles)
      if roles.empty?
        return { all: 0, super_admin: 0, admin: 0, tech_admin: 0, single_resource_admin: 0, restricted: 0 }
      end

      expressions = [
        Arel.sql("COUNT(DISTINCT user_id)"),
        count_distinct_case_sql(role_ids_for_global(roles, "super_admin")),
        count_distinct_case_sql(role_ids_for_global(roles, "admin")),
        count_distinct_case_sql(role_ids_for_global(roles, "tech_admin")),
        count_distinct_case_sql(resource_role_ids(roles)),
        restricted_count_sql(configurable_role_ids(roles)),
      ]

      counts = UserRole.where(role_id: roles.map(&:id)).pick(*expressions)
      {
        all: counts[0].to_i,
        super_admin: counts[1].to_i,
        admin: counts[2].to_i,
        tech_admin: counts[3].to_i,
        single_resource_admin: counts[4].to_i,
        restricted: counts[5].to_i
      }
    end

    def count_distinct_case_sql(ids)
      return Arel.sql("0") if ids.empty?

      Arel.sql(
        UserRole.sanitize_sql_array(["COUNT(DISTINCT CASE WHEN role_id IN (?) THEN user_id END)", ids]),
      )
    end

    def restricted_count_sql(configurable_ids)
      return Arel.sql("0") if configurable_ids.empty?

      Arel.sql(
        UserRole.sanitize_sql_array(
          ["COUNT(DISTINCT CASE WHEN role_id IN (?) AND sub_permissions IS NOT NULL THEN user_id END)",
           configurable_ids],
        ),
      )
    end
  end
end

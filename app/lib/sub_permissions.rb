# Bespoke, server-checked sub-permissions for single_resource_admin grants.
#
# A grant is one users_roles row. When its sub_permissions column is NULL the grant keeps full
# access to its resource type, exactly as before sub-permissions existed. When it holds a
# configuration, the grant may use only the clauses that configuration allows: every other
# registered clause, including clauses added later, is denied. A configuration this code cannot
# read (an unknown version, unknown keys, the wrong shape) allows nothing.
#
# Grants add up: a user is allowed a clause when any grant covering the resource allows it, and
# admins and super admins are allowed every clause.
module SubPermissions
  VERSION = 1
  ROLE_NAME = "single_resource_admin".freeze

  CLAUSES = {
    "Billboard" => %w[approve publish modify_approved].freeze
  }.freeze

  Result = Struct.new(:success?, :errors, keyword_init: true)

  def self.clauses_for(resource_type)
    CLAUSES.fetch(resource_type.to_s, [])
  end

  def self.configurable?(resource_type)
    clauses_for(resource_type).any?
  end

  def self.resource_type_for(resource)
    resource.is_a?(Class) ? resource.name : resource.class.name
  end

  def self.clause_label(resource_type, clause)
    I18n.t("lib.sub_permissions.clauses.#{resource_type.to_s.underscore}.#{clause}")
  end

  def self.clause_description(resource_type, clause)
    I18n.t("lib.sub_permissions.clause_descriptions.#{resource_type.to_s.underscore}.#{clause}", default: "")
  end

  def self.baseline_hint(resource_type)
    I18n.t("lib.sub_permissions.baseline_hints.#{resource_type.to_s.underscore}", default: "")
  end

  def self.missing_message(resource, clauses)
    resource_type = resource_type_for(resource)
    I18n.t("lib.sub_permissions.errors.missing",
           resource: resource_type,
           clauses: clauses.map { |clause| clause_label(resource_type, clause) }.to_sentence)
  end

  def self.build(allow:)
    { "version" => VERSION, "allow" => Array(allow).map(&:to_s).uniq.sort }
  end

  # The NULL test runs in SQL so a stored JSON null reads as a malformed configuration, never as
  # unrestricted.
  def self.grants_for(user:, resource:)
    resource_type = resource_type_for(resource)
    roles = Role.where(name: ROLE_NAME, resource_type: nil, resource_id: nil)
      .or(Role.where(name: ROLE_NAME, resource_type: resource_type, resource_id: nil))
    unless resource.is_a?(Class)
      roles = roles.or(Role.where(name: ROLE_NAME, resource_type: resource_type, resource_id: resource.id))
    end

    UserRole.where(user_id: user.id, role_id: roles.select(:id))
      .pluck(Arel.sql("users_roles.sub_permissions IS NULL"), :sub_permissions)
  end

  def self.update_grant(user:, resource_type:, sub_permissions:)
    unless configurable?(resource_type)
      return Result.new(success?: false, errors: [I18n.t("lib.sub_permissions.errors.not_configurable",
                                                         resource: resource_type)])
    end

    unless sub_permissions.nil?
      config = Config.new(sub_permissions, resource_type: resource_type)
      return Result.new(success?: false, errors: config.errors) unless config.valid?
    end

    role_ids = Role.where(name: ROLE_NAME, resource_type: resource_type, resource_id: nil).select(:id)
    grants = UserRole.where(user_id: user.id, role_id: role_ids)
    if grants.update_all(sub_permissions: sub_permissions, updated_at: Time.current).zero?
      return Result.new(success?: false, errors: [I18n.t("lib.sub_permissions.errors.no_grant",
                                                         resource: resource_type)])
    end

    Result.new(success?: true, errors: [])
  end
end

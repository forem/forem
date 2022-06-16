module Admin
  class UsersQuery
    QUERY_CLAUSE = "users.name ILIKE :search OR " \
                   "users.email ILIKE :search OR " \
                   "users.username ILIKE :search".freeze

    # @api public
    # @param relation [ActiveRecord::Relation<User>]
    # @param role [String, nil]
    # @param search [String, nil]
    # @param roles [Array<String>, nil]
    def self.call(relation: User.registered, role: nil, search: nil, roles: [])
      # We are at an interstitial moment where we are exposing both the role and roles param.  We
      # need to favor one or the other.
      if role.presence
        relation = relation.with_role(role, :any)
      elsif roles.presence
        relation = filter_roles(relation: relation, roles: roles)
      end

      relation = search_relation(relation, search) if search.presence
      relation.distinct.order(created_at: :desc)
    end

    def self.search_relation(relation, search)
      relation.where(QUERY_CLAUSE, search: "%#{search.strip}%")
    end

    # Apply the "where" scope to the given relation for the given roles.
    #
    # @param relation [ActiveRecord::Relation<User>]
    # @param roles [Array<String>]
    #
    # @note Why not use `relation.with_roles`; As implemented in Rolify's `.with_any_role` performs
    #       one User query per role passed.  Given that we intend to use pagination, the one User
    #       query per role is inadequate.
    #
    # @see https://github.com/RolifyCommunity/rolify/blob/0c883f4173f409766338b9c6dfc64b0fc8ec8a52/lib/rolify/finders.rb#L26-L32
    def self.filter_roles(relation:, roles:, role_map: Constants::Role::SPECIAL_ROLES_LABELS_TO_WHERE_CLAUSE)
      conditions = []
      values = []

      # Assemble the conditions and positional parameter values
      roles.each do |role|
        where_clause = role_map.fetch(role)
        resource_type = where_clause.fetch(:resource_type, nil)
        condition = "(#{Role.table_name}.name = ? AND #{Role.table_name}.resource_id IS NULL"
        values << where_clause.fetch(:name)

        # We need to use `IS NULL` instead of `= NULL` as those are different meanings.
        if resource_type.nil?
          condition += " AND #{Role.table_name}.resource_type IS NULL"
        else
          condition += " AND #{Role.table_name}.resource_type = ?"
          values << resource_type
        end
        condition += ")"
        conditions << condition
      end

      relation.joins(:roles).where(%((#{conditions.join(') OR (')})), *values)
    end
    private_class_method :filter_roles
  end
end

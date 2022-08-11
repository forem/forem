module Admin
  class UsersQuery
    SEARCH_CLAUSE = "users.name ILIKE :search OR " \
                    "users.email ILIKE :search OR " \
                    "users.username ILIKE :search".freeze

    # @api public
    # @param relation [ActiveRecord::Relation<User>]
    # @param identifier [String, nil]
    def self.find(identifier, relation: User)
      return if identifier.blank?

      relation.where(id: identifier)
        .or(relation.where(username: identifier))
        .or(relation.where(email: identifier)).first
    end

    # @api public
    # @param relation [ActiveRecord::Relation<User>]
    # @param role [String, nil]
    # @param search [String, nil]
    # @param roles [Array<String>, nil]
    # @param statuses [Array<String>, nil]
    # @param organizations [Array<String>, nil]
    # @param joining_start [String, nil]
    # @param joining_end [String, nil]
    # @param date_format [String]
    def self.call(relation: User.registered,
                  role: nil,
                  search: nil,
                  roles: [],
                  organizations: [],
                  statuses: [],
                  joining_start: nil,
                  joining_end: nil,
                  date_format: "DD/MM/YYYY")
      # We are at an interstitial moment where we are exposing both the role and roles param.  We
      # need to favor one or the other.
      if role.presence
        relation = relation.with_role(role, :any)
      elsif roles.presence || statuses.presence
        # "statuses" are a subset of roles, so we can handle these filters together
        relation = filter_roles(relation: relation, roles: [roles, statuses].compact.reduce([], :|))
      end

      if organizations.presence
        relation = filter_organization_memberships(relation: relation, organizations: organizations)
      end

      if joining_start.presence || joining_end.presence
        relation = filter_joining_date(relation: relation, joining_start: joining_start, joining_end: joining_end,
                                       date_format: date_format)
      end

      relation = search_relation(relation, search) if search.presence
      relation.distinct.order(created_at: :desc)
    end

    def self.search_relation(relation, search)
      relation.where(SEARCH_CLAUSE, search: "%#{search.strip}%")
    end

    def self.filter_joining_date(relation:, joining_start:, joining_end:, date_format:)
      ui_formats_to_parse_format = {
        "DD/MM/YYYY" => "%d/%m/%Y",
        "MM/DD/YYYY" => "%m/%d/%Y"
      }
      parse_format = ui_formats_to_parse_format.fetch(date_format)
      if joining_start.presence
        relation = relation.where("registered_at >= ?", DateTime.strptime(joining_start, parse_format).beginning_of_day)
      end

      return relation unless joining_end.presence

      relation.where("registered_at <= ?", DateTime.strptime(joining_end, parse_format).end_of_day)
    end

    def self.filter_organization_memberships(relation:, organizations:)
      sub_query = OrganizationMembership.select(:user_id).where(organization_id: organizations)
      relation.where(id: sub_query)
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
    def self.filter_roles(relation:, roles:, role_map: Constants::Role::ALL_ROLES_LABELS_TO_WHERE_CLAUSE)
      conditions = []
      values = []

      # Assemble the conditions and positional parameter values
      roles.each do |role|
        where_clause = role_map.fetch(role)

        resource_type = where_clause.fetch(:resource_type, nil)
        name = where_clause.fetch(:name)

        condition = "(#{Role.table_name}.name = ? AND #{Role.table_name}.resource_id IS NULL"
        values << name

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

      sub_query = User.select(:id).distinct.joins(:roles).where(%((#{conditions.join(') OR (')})), *values)
      relation.where(id: sub_query)
    end
    private_class_method :filter_roles
  end
end

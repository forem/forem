module Organizations
  class BulkAddUsers
    ALLOWED_ROLES = %w[member admin].freeze
    DEFAULT_ROLE = "member".freeze

    Result = Struct.new(
      :role,
      :added_users,
      :already_members,
      :not_found,
      :failed_users,
      :empty_input,
      keyword_init: true,
    ) do
      def empty_input?
        !empty_input.nil? && empty_input != false
      end
    end

    def self.call(...)
      new(...).call
    end

    def self.parse_usernames(raw_usernames)
      return [] if raw_usernames.blank?

      raw_usernames.to_s
        .split(/[,\n]/)
        .map { |u| u.strip.sub(/\A@+/, "").downcase }
        .compact_blank
        .uniq
    end

    def initialize(organization:, usernames:, role: DEFAULT_ROLE)
      @organization = organization
      @raw_usernames = usernames
      @role = ALLOWED_ROLES.include?(role.to_s) ? role.to_s : DEFAULT_ROLE
    end

    def call
      parsed_usernames = self.class.parse_usernames(raw_usernames)

      if parsed_usernames.empty?
        return Result.new(
          role: role,
          added_users: [],
          already_members: [],
          not_found: [],
          failed_users: [],
          empty_input: true,
        )
      end

      users_by_username = User.where(username: parsed_usernames).index_by { |u| u.username.downcase }
      existing_member_user_ids = organization.organization_memberships
        .where(user_id: users_by_username.values.map(&:id))
        .pluck(:user_id)
        .to_set

      added_users = []
      already_members = []
      not_found = []
      failed_users = []

      parsed_usernames.each do |username|
        user = users_by_username[username]

        if user.nil?
          not_found << username
        elsif existing_member_user_ids.include?(user.id)
          already_members << user.username
        else
          membership = organization.organization_memberships.build(user: user, type_of_user: role)
          begin
            if membership.save
              added_users << user.username
            else
              failed_users << "#{user.username} (#{membership.errors_as_sentence})"
            end
          rescue ActiveRecord::RecordNotUnique
            already_members << user.username
          end
        end
      end

      Result.new(
        role: role,
        added_users: added_users,
        already_members: already_members,
        not_found: not_found,
        failed_users: failed_users,
        empty_input: false,
      )
    end

    private

    attr_reader :organization, :raw_usernames, :role
  end
end

module Users
  module ApprovedLiquidTags
    RESTRICTED_LIQUID_TAGS = [UserSubscriptionTag].freeze

    def self.call(user)
      return [] unless user

      RESTRICTED_LIQUID_TAGS.filter_map do |liquid_tag|
        liquid_tag if liquid_tag::VALID_ROLES.any? { |role| user.has_role?(*Array(role)) }
      end
    end
  end
end

module Users
  module ApprovedLiquidTags
    # TODO: Should this include PollTag
    RESTRICTED_LIQUID_TAGS = [UserSubscriptionTag].freeze

    def self.call(user)
      return [] unless user

      RESTRICTED_LIQUID_TAGS.filter_map do |liquid_tag|
        # TODO: Should we instead consider asking the liquid tag?
        liquid_tag if liquid_tag.user_authorization_method_name &&
          user.public_send(liquid_tag.user_authorization_method_name)
      end
    end
  end
end

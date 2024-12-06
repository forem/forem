module Devise
  module Models
    module Authenticatable
      list = %i[
        invitation_token invitation_created_at invitation_sent_at
        invitation_accepted_at invitation_limit invited_by_type
        invited_by_id invitations_count
      ]
      
      if defined?(UNSAFE_ATTRIBUTES_FOR_SERIALIZATION)
        UNSAFE_ATTRIBUTES_FOR_SERIALIZATION.concat(list)
      else
        BLACKLIST_FOR_SERIALIZATION.concat(list)
      end
    end
  end
end

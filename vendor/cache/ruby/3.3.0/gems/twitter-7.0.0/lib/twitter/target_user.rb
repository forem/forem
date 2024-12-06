require 'twitter/basic_user'

module Twitter
  class TargetUser < Twitter::BasicUser
    predicate_attr_reader :followed_by
  end
end

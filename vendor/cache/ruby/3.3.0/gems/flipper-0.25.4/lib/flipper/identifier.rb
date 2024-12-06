module Flipper
  # A default implementation of `#flipper_id` for actors.
  #
  #   class User < Struct.new(:id)
  #     include Flipper::Identifier
  #   end
  #
  #   user = User.new(99)
  #   Flipper.enable :thing, user
  #   Flipper.enabled? :thing, user #=> true
  #
  module Identifier
    def flipper_id
      "#{self.class.name};#{id}"
    end
  end
end

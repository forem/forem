class UserTag < LiquidTagBase
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  PARTIAL = "users/liquid".freeze

  def initialize(_tag_name, user, _tokens)
    @user = user.delete(" ")

    class << self
      def render(_context)
        user = parse_username_to_user
        follow_button = follow_button(user)
        profile_img = ProfileImage.new(user).get(150)
        user_colors = user_colors(user)
        ActionController::Base.new.render_to_string(
          partial: PARTIAL,
          locals: {
            user: user,
            follow_button: follow_button,
            profile_img: profile_img,
            user_colors: user_colors
          },
        )
      end

      def parse_username_to_user
        user = User.find_by(username: @user)
        raise StandardError, "invalid username" if user.nil?

        user
      end
    end
  end
end

Liquid::Template.register_tag("user", UserTag)

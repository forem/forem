class UserTag < LiquidTagBase
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  PARTIAL = "users/liquid".freeze

  def initialize(_tag_name, user, _tokens)
    @user = parse_username_to_user(user.delete(" "))
    return if user_not_found?

    @follow_button = follow_button(@user)
    @user_colors = user_colors(@user)
  end

  def render(_context)
    return @user if user_not_found?

    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        user: @user,
        follow_button: @follow_button,
        user_colors: @user_colors
      },
    )
  end

  def parse_username_to_user(username)
    user = User.find_by(username: username)
    return username if user.nil?

    user
  end

  def user_not_found?
    @user.is_a?(String)
  end
end

Liquid::Template.register_tag("user", UserTag)

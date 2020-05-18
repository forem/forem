class UserTag < LiquidTagBase
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  PARTIAL = "users/liquid".freeze

  def initialize(_tag_name, user, _tokens)
    @user = parse_username_to_user(user.delete(" "))
    @follow_button = follow_button(@user)
    @user_colors = user_colors(@user)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        user: @user.decorate,
        follow_button: @follow_button,
        user_colors: @user_colors,
        user_path: path_to_profile(@user)
      },
    )
  end

  def parse_username_to_user(user)
    User.find_by(username: user) || deleted_user
  end

  private

  def deleted_user
    User.new(username: "[deleted user]", name: "[Deleted User]")
  end

  def path_to_profile(user)
    user.username == "[deleted user]" ? nil : user.path
  end
end

Liquid::Template.register_tag("user", UserTag)

class UserTag < LiquidTagBase
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  PARTIAL = "users/liquid".freeze

  def initialize(_tag_name, input, _parse_context)
    super

    username = input.gsub("#{URL.url}/", "").delete(" ")
    @user = parse_username_to_user(username)
    @user_colors = user_colors(@user)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        user: @user.decorate,
        user_colors: @user_colors,
        user_path: @user.path
      },
    )
  end

  private

  def parse_username_to_user(user)
    User.find_by(username: user, registered: true) || Users::DeletedUser
  end
end

Liquid::Template.register_tag("user", UserTag)

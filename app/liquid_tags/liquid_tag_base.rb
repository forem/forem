class LiquidTagBase < Liquid::Tag
  include ApplicationHelper
  include TagHelper
  include ActionView::Helpers::TagHelper

  def self.script
    ""
  end

  def finalize_html(input)
    input.gsub(/ {2,}/, "").
      gsub(/\n/m, " ").
      gsub(/>\n{1,}</m, "><").
      strip.
      html_safe
  end

  def render(_context)
    organization_or_user = if @organization
                             { organization: @organization, organization_colors: @organization_colors }
                           else
                             { user: @user, user_colors: @user_colors }
                           end
    locals = { follow_button: @follow_button, user_colors: @user_colors }.merge(organization_or_user)

    ActionController::Base.new.render_to_string(partial: partial_file, locals: locals)
  end
end

class UserTag < LiquidTagBase
  include ApplicationHelper
  attr_reader :user

  def initialize(tag_name, user, tokens)
    @user = parse_username_to_user(user)
  end

  def render(context)
    # looks like link liquid tag
    <<-HTML
    <style>
      .ltag__user .follow-action-button{
        background-color: #{user_colors(@user)[:bg]} !important;
        color: #{user_colors(@user)[:text]} !important;
        border-color: #{ user_colors(@user)[:bg].downcase == '#ffffff' ? user_colors(@user)[:text] : user_colors(@user)[:bg] } !important;
      }
    </style>
    <div class="ltag__user" style="border-color:#{@user.decorate.darker_color};box-shadow: 3px 3px 0px #{@user.decorate.darker_color}">
      <a href="/#{@user.username}" class="ltag__user__link profile-image-link">
        <div class="ltag__user__pic">
          <img src="#{ProfileImage.new(@user).get(150)}" alt="#{@user.username} image"/>
        </div>
      </a>
        <div class="ltag__user__content">
          <h2><a href="#{@user.path}" class="ltag__user__link">#{@user.name}</a> #{follow_button(@user)}</h2>
          <div class="ltag__user__summary">
            <a href="/#{@user.username}" class="ltag__user__link">
              #{@user.summary}
            </a>
          </div>
        </div>
    </div>
    HTML
  end

  private

  def accent_color
    HexComparer.new([ApplicationController.helpers.user_colors(@user)[:bg]]).accent
  end

  def parse_username_to_user(input)
    input_no_space = input.delete(" ")
    user = User.find_by_username(input_no_space)
    if user.nil?
      raise StandardError, "invalid username"
    else
      user
    end
  end

  def twitter_link
    if @user.twitter_username.present?
      <<-HTML
      <a href="http://twitter.com/#{@user.twitter_username}" target="_blank" rel="noopener">
        #{image_tag('/assets/twitter-logo.svg', class:'icon-img', alt: 'twitter')} #{@user.twitter_username}
      </a>
      HTML
    end
  end

  def github_link
    if @user.github_username.present?
      <<-HTML
      <a href="http://github.com/#{@user.github_username}" target="_blank" rel="noopener">
        #{image_tag('/assets/github-logo.svg', class:'icon-img', alt: 'github')} #{@user.github_username}
      </a>
      HTML
    end
  end

  def website_link
    if @user.website_url.present?
      <<-HTML
      <a href="#{@user.website_url}" target="_blank" rel="noopener">
        #{image_tag('/assets/link.svg', class:'icon-img', alt: 'website link')} #{beautified_url(@user.website_url)}
      </a>
      HTML
    end
  end
end

Liquid::Template.register_tag("user", UserTag)

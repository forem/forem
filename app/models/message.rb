class Message < ApplicationRecord
  belongs_to :user
  belongs_to :chat_channel

  validates :message_html, presence: true
  validates :message_markdown, presence: true, length: { maximum: 1024 }
  validate :channel_permission

  before_validation :determine_user_validity
  before_validation :evaluate_markdown
  after_create      :send_email_if_appropriate
  after_create      :update_chat_channel_last_message_at
  after_create      :update_all_has_unopened_messages_statuses

  def preferred_user_color
    color_options = [user.bg_color_hex || "#000000", user.text_color_hex || "#000000"]
    HexComparer.new(color_options).brightness(0.9)
  end

  def direct_receiver
    return if chat_channel.group?

    chat_channel.users.where.not(id: user.id).first
  end

  private

  def update_chat_channel_last_message_at
    chat_channel.touch(:last_message_at)
    chat_channel.chat_channel_memberships.each(&:index_to_elasticsearch)
  end

  def update_all_has_unopened_messages_statuses
    chat_channel.
      chat_channel_memberships.
      where("last_opened_at < ?", 10.seconds.ago).
      where.not(user_id: user_id).
      update_all(has_unopened_messages: true)
  end

  def evaluate_markdown
    html = MarkdownParser.new(message_markdown).evaluate_markdown
    html = append_rich_links(html)
    html = wrap_mentions_with_links(html)
    self.message_html = html
  end

  def wrap_mentions_with_links(html)
    return unless html

    html_doc = Nokogiri::HTML(html)

    # looks for nodes that isn't <code>, <a>, and contains "@"
    targets = html_doc.xpath('//html/body/*[not (self::code) and not(self::a) and contains(., "@")]').to_a

    # A Queue system to look for and replace possible usernames
    until targets.empty?
      node = targets.shift

      # only focus on portion of text with "@"
      node.xpath("text()[contains(.,'@')]").each do |el|
        el.replace(el.text.gsub(/\B@[a-z0-9_-]+/i) { |text| user_link_if_exists(text) })
      end

      # enqueue children that has @ in it's text
      children = node.xpath('*[not(self::code) and not(self::a) and contains(., "@")]').to_a
      targets.concat(children)
    end

    if html_doc.at_css("body")
      html_doc.at_css("body").inner_html
    else
      html_doc.to_html
    end
  end

  def user_link_if_exists(mention)
    username = mention.delete("@").downcase
    if User.find_by(username: username) && chat_channel.group?
      <<~HTML
        <a class='comment-mentioned-user' data-content="sidecar-user" href='/#{username}' target="_blank">@#{username}</a>
      HTML
    elsif username == "all" && chat_channel.channel_type == "invite_only"
      <<~HTML
        <a class='comment-mentioned-user comment-mentioned-all' data-content="chat_channels/#{chat_channel.id}" href='#' target="_blank">@#{username}</a>
      HTML
    else
      mention
    end
  end

  def append_rich_links(html)
    doc = Nokogiri::HTML(html)
    doc.css("a").each do |anchor|
      if (article = rich_link_article(anchor))
        html += "<a href='#{article.current_state_path}'
        class='chatchannels__richlink'
          target='_blank' data-content='sidecar-article'>
            #{"<div class='chatchannels__richlinkmainimage' style='background-image:url(" + cl_path(article.main_image) + ")' data-content='sidecar-article' ></div>" if article.main_image.present?}
          <h1 data-content='sidecar-article'>#{article.title}</h1>
          <h4 data-content='sidecar-article'><img src='#{ProfileImage.new(article.cached_user).get(width: 90)}' /> #{article.cached_user.name}・#{article.readable_publish_date || 'Draft Post'}</h4>
          </a>".html_safe
      elsif (tag = rich_link_tag(anchor))
        html += "<a href='/t/#{tag.name}'
        class='chatchannels__richlink'
          target='_blank' data-content='sidecar-tag'>
          <h1 data-content='sidecar-tag'>
            #{"<img src='" + cl_path(tag.badge.badge_image_url) + "' data-content='sidecar-tag' style='transform:rotate(-5deg)' />" if tag.badge_id.present?}
            ##{tag.name}
          </h1>
          </a>".html_safe
      elsif (user = rich_user_link(anchor))
        html += "<a href='#{user.path}'
        class='chatchannels__richlink'
          target='_blank' data-content='sidecar-user'>
          <h1 data-content='sidecar-user'>
            <img src='#{ProfileImage.new(user).get(width: 90)}' data-content='sidecar-user' class='chatchannels__richlinkprofilepic' />
            #{user.name}
          </h1>
          </a>".html_safe
      end
    end
    html
  end

  def cl_path(img_src)
    ActionController::Base.helpers.
      cl_image_path(img_src,
                    type: "fetch",
                    width: 725,
                    crop: "limit",
                    flags: "progressive",
                    fetch_format: "auto",
                    sign_url: true)
  end

  def determine_user_validity
    return unless chat_channel

    user_ok = chat_channel.status == "active" && (chat_channel.has_member?(user) || chat_channel.channel_type == "open")
    errors.add(:base, "You are not a participant of this chat channel.") unless user_ok
  end

  def channel_permission
    errors.add(:base, "Must be part of channel.") if chat_channel_id.blank?

    channel = ChatChannel.find(chat_channel_id)
    return if channel.open?

    errors.add(:base, "You are not a participant of this chat channel.") unless channel.has_member?(user)
    errors.add(:base, "Something went wrong") if channel.status == "blocked"
  end

  def rich_link_article(link)
    Article.find_by(slug: link["href"].split("/")[4].split("?")[0]) if link["href"].include?("//#{ApplicationConfig['APP_DOMAIN']}/") && link["href"].split("/")[4]
  end

  def rich_link_tag(link)
    Tag.find_by(name: link["href"].split("/t/")[1].split("/")[0]) if link["href"].include?("//#{ApplicationConfig['APP_DOMAIN']}/t/")
  end

  def rich_user_link(link)
    User.find_by(username: link["href"].split("/")[3].split("/")[0]) if link["href"].include?("//#{ApplicationConfig['APP_DOMAIN']}/")
  end

  def send_email_if_appropriate
    recipient = direct_receiver
    return if !chat_channel.direct? ||
      recipient.updated_at > 1.hour.ago ||
      recipient.chat_channel_memberships.order("last_opened_at DESC").
        first.last_opened_at > 15.hours.ago ||
      chat_channel.last_message_at > 30.minutes.ago ||
      recipient.email_connect_messages == false

    NotifyMailer.new_message_email(self).deliver
  end
end

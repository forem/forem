module ApplicationHelper
  LARGE_USERBASE_THRESHOLD = 1000

  def subtitles
    {
      "week" => I18n.t("helpers.application_helper.subtitle.week"),
      "month" => I18n.t("helpers.application_helper.subtitle.month"),
      "year" => I18n.t("helpers.application_helper.subtitle.year"),
      "infinity" => I18n.t("helpers.application_helper.subtitle.infinity"),
      "latest" => I18n.t("helpers.application_helper.subtitle.latest")
    }
  end

  def user_logged_in_status
    user_signed_in? ? "logged-in" : "logged-out"
  end

  def current_page
    "#{controller_name}-#{controller.action_name}"
  end

  # rubocop:disable Rails/HelperInstanceVariable
  def view_class
    if @podcast_episode_show # custom due to edge cases
      "stories stories-show podcast_episodes-show"
    elsif @story_show
      "stories stories-show"
    else
      "#{controller_name} #{controller_name}-#{controller.action_name}"
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable

  def title(page_title)
    derived_title = if page_title.include?(community_name)
                      page_title
                    elsif user_signed_in?
                      "#{page_title} - #{community_name} #{community_emoji}"
                    else
                      "#{page_title} - #{community_name}"
                    end
    content_for(:title) { derived_title }
    derived_title
  end

  def title_with_timeframe(page_title:, timeframe:, content_for: false)
    if timeframe.blank? || subtitles[timeframe].blank?
      return content_for ? title(page_title) : page_title
    end

    title_text = I18n.t("helpers.application_helper.title_text", title: page_title,
                                                                 timeframe: subtitles.fetch(timeframe))
    content_for ? title(title_text) : title_text
  end

  def optimized_image_url(url, width: 500, quality: 80, fetch_format: "auto", random_fallback: true)
    fallback_image = asset_path("#{rand(1..40)}.png") if random_fallback

    return unless (image_url = url.presence || fallback_image)

    normalized_url = Addressable::URI.parse(image_url).normalize.to_s
    Images::Optimizer.call(normalized_url, width: width, quality: quality, fetch_format: fetch_format)
  end

  def optimized_image_tag(image_url, optimizer_options: {}, image_options: {})
    image_options[:width] ||= optimizer_options[:width]
    image_options[:height] ||= optimizer_options[:height]
    updated_image_url = Images::Optimizer.call(image_url, **optimizer_options)

    image_tag(updated_image_url, image_options)
  end

  def cloud_cover_url(url)
    CloudCoverUrl.new(url).call
  end

  def tag_colors(tag)
    Rails.cache.fetch("view-helper-#{tag}/tag_colors", expires_in: 5.hours) do
      if (found_tag = Tag.select(%i[bg_color_hex text_color_hex]).find_by(name: tag))
        { background: found_tag.bg_color_hex, color: found_tag.text_color_hex }
      else
        { background: "#d6d9e0", color: "#606570" }
      end
    end
  end

  def any_enabled_auth_providers?
    authentication_enabled_providers.any?
  end

  def beautified_url(url)
    url.sub(%r{\A((https?|ftp):/)?/}, "").sub(/\?.*/, "").chomp("/")
  rescue StandardError
    url
  end

  def org_bg_or_white(org)
    org&.bg_color_hex ? org.bg_color_hex : "#ffffff"
  end

  def sanitize_rendered_markdown(processed_html)
    ActionController::Base.helpers.sanitize processed_html,
                                            scrubber: RenderedMarkdownScrubber.new
  end

  def sanitized_sidebar(text)
    ActionController::Base.helpers.sanitize simple_format(text),
                                            tags: MarkdownProcessor::AllowedTags::SIDEBAR
  end

  def follow_button(followable, style = "full", classes = "")
    return if followable == Users::DeletedUser

    user_follow = followable.instance_of?(User) ? "follow-user" : ""
    followable_type = followable.class_name
    followable_name = followable.name

    tag.button(
      I18n.t("helpers.application_helper.follow.text.#{followable_type}",
             default: I18n.t("helpers.application_helper.follow.text.default")),
      name: :button,
      type: :button,
      data: {
        info: DataInfo.to_json(object: followable, className: followable_type, style: style)
      },
      class: "crayons-btn follow-action-button whitespace-nowrap #{classes} #{user_follow}",
      aria: {
        label: I18n.t("helpers.application_helper.follow.aria_label.#{followable_type}",
                      name: followable_name,
                      default: I18n.t("helpers.application_helper.follow.aria_label.default", type: followable_type,
                                                                                              name: followable_name)),
        pressed: "false"
      },
    )
  end

  def user_colors_style(user)
    "border: 2px solid #{user.decorate.darker_color}; \
    box-shadow: 5px 6px 0px #{user.decorate.darker_color}"
  end

  def user_colors(user)
    user.decorate.enriched_colors
  end

  def timeframe_check(given_timeframe)
    params[:timeframe] == given_timeframe
  end

  def list_path
    return "" if params[:tag].blank?

    "/t/#{params[:tag]}"
  end

  def logo_svg
    if Settings::General.logo_svg.present?
      Settings::General.logo_svg.html_safe # rubocop:disable Rails/OutputSafety
    else
      inline_svg_tag("devplain.svg", class: "logo", size: "20% * 20%", aria: true,
                                     title: I18n.t("helpers.application_helper.app_logo"))
    end
  end

  def community_name
    @community_name ||= Settings::Community.community_name
  end

  def community_emoji
    @community_emoji ||= Settings::Community.community_emoji
  end

  def release_adjusted_cache_key(path)
    release_footprint = ForemInstance.deployed_at
    return path if release_footprint.blank?

    "#{path}-#{params[:locale]}-#{release_footprint}-#{Settings::General.admin_action_taken_at.rfc3339}"
  end

  def copyright_notice
    start_year = Settings::Community.copyright_start_year.to_s
    current_year = Time.current.year.to_s
    return start_year if current_year == start_year
    return current_year if start_year.strip.length < 4 # 978 is not a valid year!

    "#{start_year} - #{current_year}"
  end

  def collection_link(collection, **kwargs)
    size_string = I18n.t("views.articles.series.size", count: collection.articles.published.size)
    body = if collection.slug.present?
             I18n.t("views.articles.series.subtitle", slug: collection.slug,
                                                      size: size_string)
           else
             size_string
           end

    link_to body, collection.path, **kwargs
  end

  def email_link(text: nil, additional_info: nil)
    email = ForemInstance.email
    mail_to email, text || email, additional_info
  end

  def community_members_label
    Settings::Community.member_label.pluralize
  end

  def meta_keywords_default
    return if Settings::General.meta_keywords[:default].blank?

    tag.meta name: "keywords", content: Settings::General.meta_keywords[:default]
  end

  def meta_keywords_article(article_tags = nil)
    return if Settings::General.meta_keywords[:article].blank?

    content = if article_tags.present?
                "#{article_tags}, #{Settings::General.meta_keywords[:article]}"
              else
                Settings::General.meta_keywords[:article]
              end

    tag.meta name: "keywords", content: content
  end

  def meta_keywords_tag(tag_name)
    return if Settings::General.meta_keywords[:tag].blank?

    tag.meta name: "keywords", content: "#{Settings::General.meta_keywords[:tag]}, #{tag_name}"
  end

  def app_url(uri = nil)
    URL.url(uri)
  end

  def article_url(article)
    URL.article(article)
  end

  def comment_url(comment)
    URL.comment(comment)
  end

  def reaction_url(reaction)
    URL.reaction(reaction)
  end

  def tag_url(tag, page = 1)
    URL.tag(tag, page)
  end

  def user_url(user)
    URL.user(user)
  end

  def organization_url(organization)
    URL.organization(organization)
  end

  def estimated_user_count
    User.registered.estimated_count
  end

  def display_estimated_user_count?
    estimated_user_count > LARGE_USERBASE_THRESHOLD
  end

  def admin_config_label(method, content = nil, model: Settings::General)
    content ||= tag.span(method.to_s.humanize)

    label_prefix = model.name.split("::").map(&:underscore).join("_")
    tag.label(content, class: "site-config__label crayons-field__label", for: "#{label_prefix}_#{method}")
  end

  def admin_config_description(content)
    tag.p(content, class: "crayons-field__description") unless content.empty?
  end

  def role_display_name(role)
    role.name.titlecase
  end

  def render_tag_link(tag, filled: false, monochrome: false, classes: "")
    color = tag_colors(tag)[:background].presence || Settings::UserExperience.primary_brand_color_hex
    color_faded = Color::CompareHex.new([color]).opacity(0.1)
    label = safe_join([content_tag(:span, "#", class: "crayons-tag__prefix"), tag])

    options = {
      class: "crayons-tag #{'crayons-tag--filled' if filled} #{'crayons-tag--monochrome' if monochrome} #{classes}",
      style: "
        --tag-bg: #{color_faded};
        --tag-prefix: #{color};
        --tag-bg-hover: #{color_faded};
        --tag-prefix-hover: #{color};
      "
    }

    link_to(label, tag_path(tag), options)
  end

  def creator_settings_form?
    return unless FeatureFlag.enabled?(:creator_onboarding)
    return unless User.with_role(:creator).any?

    creator = User.with_role(:creator).first
    !creator.checked_code_of_conduct && !creator.checked_terms_and_conditions
  end
end

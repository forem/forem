module ApplicationHelper
  def user_logged_in_status
    user_signed_in? ? "logged-in" : "logged-out"
  end

  def current_page
    "#{controller_name}-#{controller.action_name}"
  end

  def view_class
    if @podcast_episode_show # custom due to edge cases
      "stories stories-show podcast_episodes-show"
    elsif @story_show
      "stories stories-show"
    else
      "#{controller_name} #{controller_name}-#{controller.action_name}"
    end
  end

  def title(page_title)
    derived_title = if page_title.include?(ApplicationConfig["COMMUNITY_NAME"])
                      page_title
                    else
                      page_title + " - #{ApplicationConfig['COMMUNITY_NAME']} Community 👩‍💻👨‍💻"
                    end
    content_for(:title) { derived_title }
    derived_title
  end

  def title_with_timeframe(page_title:, timeframe:, content_for: false)
    sub_titles = {
      "week" => "Top posts this week",
      "month" => "Top posts this month",
      "year" => "Top posts this year",
      "infinity" => "All posts",
      "latest" => "Latest posts"
    }

    if timeframe.blank? || sub_titles[timeframe].blank?
      return content_for ? title(page_title) : page_title
    end

    title_text = "#{page_title} - #{sub_titles.fetch(timeframe)}"
    content_for ? title(title_text) : title_text
  end

  def icon(name, pixels = "20")
    image_tag(icon_url(name), alt: name, class: "icon-img", height: pixels, width: pixels)
  end

  def icon_url(name)
    postfix = {
      "twitter" => "v1456342401/twitter-logo-silhouette_1_letrqc.png",
      "github" => "v1456342401/github-logo_m841aq.png",
      "link" => "v1456342401/link-symbol_apfbll.png",
      "volume" => "v1461589297/technology_1_aefet2.png",
      "volume-mute" => "v1461589297/technology_jiugwb.png"
    }.fetch(name, "v1456342953/star-in-black-of-five-points-shape_sor40l.png")

    "https://res.cloudinary.com/#{ApplicationConfig['CLOUDINARY_CLOUD_NAME']}/image/upload/#{postfix}"
  end

  def cloudinary(url, width = nil, _quality = 80, _format = "jpg")
    return url if Rails.env.development? && (url.blank? || url.exclude?("http"))

    service_path = "https://res.cloudinary.com/#{ApplicationConfig['CLOUDINARY_CLOUD_NAME']}/image/fetch"

    if url&.size&.positive?
      if width
        "#{service_path}/c_scale,fl_progressive,q_auto,w_#{width}/f_auto/#{url}"
      else
        "#{service_path}/c_scale,fl_progressive,q_auto/f_auto/#{url}"
      end
    else
      "#{service_path}/c_scale,fl_progressive,q_1/f_auto/https://pbs.twimg.com/profile_images/481625927911092224/iAVNQXjn_normal.jpeg"
    end
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

  def beautified_url(url)
    url.sub(/\A((http[s]?|ftp):\/)?\//, "").sub(/\?.*/, "").chomp("/")
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
                                            tags: %w[p b i em strike strong u br]
  end

  def follow_button(followable, style = "full")
    tag :button, # Yikes
        class: "cta follow-action-button",
        data: {
          :info => { id: followable.id, className: followable.class.name, style: style }.to_json,
          "follow-action-button" => true
        }
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
    if SiteConfig.logo_svg.present?
      SiteConfig.logo_svg.html_safe
    else
      inline_svg_tag("devplain.svg", class: "logo", size: "20% * 20%", aria: true, title: "App logo")
    end
  end

  def community_qualified_name
    "The #{ApplicationConfig['COMMUNITY_NAME']} Community"
  end

  def cache_key_heroku_slug(path)
    heroku_slug_commit = ApplicationConfig["HEROKU_SLUG_COMMIT"]
    return path if heroku_slug_commit.blank?

    "#{path}-#{heroku_slug_commit}"
  end

  # Creates an app internal URL
  #
  # @note Uses protocol and domain specified in the environment, ensure they are set.
  # @param uri [URI, String] parts we want to merge into the URL, e.g. path, fragment
  # @example Retrieve the base URL
  #  app_url #=> "https://dev.to"
  # @example Add a path
  #  app_url("internal") #=> "https://dev.to/internal"
  def app_url(uri = nil)
    URL.url(uri)
  end

  def tag_url(tag, page)
    URL.tag(tag, page)
  end

  def article_url(article)
    URL.article(article)
  end

  def user_url(user)
    URL.user(user)
  end
end

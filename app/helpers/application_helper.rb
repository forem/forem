module ApplicationHelper

  def user_logged_in_status
    user_signed_in? ? "logged-in" : "logged-out"
  end

  def current_page
    "#{controller_name}-#{controller.action_name}"
  end

  def view_class
    "#{controller_name} #{controller_name}-#{controller.action_name}"
  end

  def core_pages?
    controller_name == "articles" ||
      controller_name == "podcast_episodes" ||
      controller_name == "events" ||
      controller_name == "users" ||
      controller_name == "pages" ||
      controller_name == "dashboards"||
      controller_name == "stories" ||
      controller_name == "comments" ||
      controller_name == "notifications" ||
      controller_name == "reading_list_items"
  end

  def render_js?
    !((controller_name == "articles" && (controller.action_name == "index" || controller.action_name == "show")) || controller_name == "pulses")
  end

  def title(page_title)
    content_for(:title){ page_title }
    page_title
  end

  def icon(name,pixels="20")
    image_tag icon_url(name), alt: name, class:"icon-img", height: pixels, width: pixels
  end

  def icon_url(name)
    prefix = "https://res.cloudinary.com/practicaldev/image/upload/"
    case name
    when "twitter"
      url = prefix+"v1456342401/twitter-logo-silhouette_1_letrqc.png"
    when "github"
      url = prefix+"v1456342401/github-logo_m841aq.png"
    when "link"
      url = prefix+"v1456342401/link-symbol_apfbll.png"
    when "volume"
      url = prefix+"v1461589297/technology_1_aefet2.png"
    when "volume-mute"
      url = prefix+"v1461589297/technology_jiugwb.png"
    else
      url = prefix+"v1456342953/star-in-black-of-five-points-shape_sor40l.png"
    end
  end

  def cloudinary(url,width=nil,quality=80,format="jpg")
    if Rails.env.development? && (url.blank? || !url.include?("http"))
      url = "http://www.lawyersweekly.com.au/images/LW_Media_Library/594partner-profile-pic-An.jpg"
    end
    if url && url.size > 0
      if width
        "https://res.cloudinary.com/practicaldev/image/fetch/c_scale,fl_progressive,q_auto,w_#{width}/f_auto/#{url}"
      else
        "https://res.cloudinary.com/practicaldev/image/fetch/c_scale,fl_progressive,q_auto/f_auto/#{url}"
      end
    else
      "https://res.cloudinary.com/practicaldev/image/fetch/c_scale,fl_progressive,q_1/f_auto/https://pbs.twimg.com/profile_images/481625927911092224/iAVNQXjn_normal.jpeg"
    end
  end

  def cloud_cover_url(url)
    return nil unless url.present?
      width = 1000
      height = 420
      quality = "auto"

      cl_image_path(url,
       :type=>"fetch",
       :width => width,
       :height => height,
       :crop => "imagga_scale",
       :quality => quality,
       :flags => "progressive",
       :fetch_format => "auto",
       :sign_url => true)
  end

  def cloud_social_image(article)
    Rails.cache.
      fetch("article-social-img-#{article}-#{article.updated_at}-#{article.comments_count}",
      expires_in: 1.hour) do
      src = GeneratedImage.new(article).social_image
      return src if src.include? "res.cloudinary"
      cl_image_path(src,
      type: "fetch",
      width:  "1000",
      height: "500",
      crop: "imagga_scale",
      quality: "auto",
      flags: "progressive",
      fetch_format: "auto",
      sign_url: true)
    end
  end

  def tag_colors(tag)
    Rails.cache.fetch("view-helper-#{tag}/tag_colors", expires_in: 5.hours) do
      if found_tag = Tag.find_by_name(tag)
        {background:found_tag.bg_color_hex,color:found_tag.text_color_hex}
      else
        {background:"#d6d9e0",color:"#606570"}
      end
    end
  end

  def beautified_url(url)
    begin
      url.sub(/^((http[s]?|ftp):\/)?\//, '').sub(/\?.*/, '').chomp('/')
    rescue
      url
    end
  end

  def org_bg_or_white(org)
    return "#ffffff" unless (org && org.bg_color_hex)
    org.bg_color_hex
  end

  def org_text_or_blue(org)
    return "#557de8" unless (org && org.text_color_hex)
    org.text_color_hex
  end

  def sanitized_article_body(processed_html)
    ActionController::Base.helpers.sanitize processed_html.html_safe,
      tags: %w(button strong em a table tbody thead tfoot th tr td col colgroup del p h1 h2 h3 h4 h5 h6 blockquote time div span i em u b ul ol li dd dl dt q code pre img sup sub cite center br small hr video source figcaption add ruby rp rt),
      attributes: %w(href strong em class ref rel src title alt colspan height width size rowspan span value start data-conversation data-lang data-no-instant data-url id name type loop)
  end

  def sanitized_sidebar(text)
    ActionController::Base.helpers.sanitize simple_format(text),
      tags: %w(p, b, i, em, strike, strong, u, br),
      attributes: %w()
  end

  def track_split_version(url,version)
    "trackOutboundLink('#{url}','#{version}'); return false;"
  end

  def follow_button(followable,style="full")
    "<button class='cta follow-action-button' data-info='{\"id\":#{followable.id},\"className\":\"#{followable.class.name}\",\"style\":\"#{style}\"}' data-follow-action-button>&nbsp;</button>".html_safe
  end

  def user_colors_style(user)
    "background-color:#{user_colors(user)[:bg]};color:#{user_colors(user)[:text]}"
  end

  def user_colors(user)
    if user.bg_color_hex.blank?
      {
        bg: assigned_color(user)[:bg],
        text: assigned_color(user)[:text]
      }
    else
      {
        bg: user.bg_color_hex || assigned_color(user)[:bg],
        text: user.text_color_hex || assigned_color(user)[:text]
      }
    end
  end

  def assigned_color(user)
    colors = [
              {
                bg: "#093656",
                text: "#ffffff"
              },
              {
                bg: "#19063A",
                text: "#dce9f3"
              },
              {
                bg: "#0D4D4B",
                text: "#fdf9f3"
              },
              {
                bg: "#61122f",
                text: "#ffffff"
              },
              {
                bg: "#edebf6",
                text:" #070126"
              },
              {
                bg: "#080E3B",
                text: "#ffffff"
              },
              {
                bg: "#010C1F",
                text: "#aebcd5"
              },
              {
                bg: "#d7dee2",
                text: "#022235"
              },
              {
                bg: "#161616",
                text: "#66e2d5"
              },
              {
                bg: "#1c0bba",
                text: "#c9d2dd"
              },
            ]
    colors[user.id % 10]
  end

  def timeframe_check(given_timeframe)
    params[:timeframe] == given_timeframe
  end

  def list_path
    if params[:tag].present?
      "/t/#{params[:tag]}"
    else
      ""
    end
  end
end

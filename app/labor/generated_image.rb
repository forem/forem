class GeneratedImage
  include CloudinaryHelper
  attr_reader :article

  def initialize(article)
    @article = article.decorate
  end

  def social_image
    return article.social_image if article.social_image.present?
    return article.main_image if article.main_image.present?
    generated
  end

  def generated
    img = she_coded_image_path(article) if article.cached_tag_list_array.include? "shecoded"
    img = they_coded_image_path(article) if article.cached_tag_list_array.include? "theycoded"
    img = discuss_image_path(article) if article.cached_tag_list_array.include? "discuss"
    img || default_social_image(article)
  end

  def she_coded_image_path(article)
    user_name = article.user.name.length >= 15 ? article.user.name.split(" ").first : article.user.name
    she_coded_font_size = user_name.length >= 13 ? 38 : 52
    path = cl_image_path(article.user.profile_image_url || "http://41orchard.com/wp-content/uploads/2011/12/Robot-Chalkboard-Decal.gif",
      sign_url: true, type: "fetch", transformation: [
        { height: 133, width: 133, radius: "max", crop: "imagga_scale" },
        { underlay: "nevertheless-she-coded-08_vbwnoc", x: "280", y: "10" },
        { overlay: "text:NixieOne.ttf_#{she_coded_font_size}_normal_normal_normal_left_FFFFFF_2:Nevertheless%252C%0A#{user_name}%20Coded", color: "#FFFFFF", gravity: "west", x: "230", y: "-5", w: "150", bo: "FFFFFF_2" },
    ])
    "#{path}?shecoded&t=#{Time.now.to_i}"
  end

  def they_coded_image_path(article)
    user_name = article.user.name.length >= 15 ? article.user.name.split(" ").first : article.user.name
    she_coded_font_size = user_name.length >= 13 ? 38 : 52
    path = cl_image_path(article.user.profile_image_url || "http://41orchard.com/wp-content/uploads/2011/12/Robot-Chalkboard-Decal.gif",
      sign_url: true, type: "fetch", transformation: [
        { height: 133, width: 133, radius: "max", crop: "imagga_scale" },
        { underlay: "they-coded_jjrvze", x: "280", y: "10" },
        { overlay: "text:NixieOne.ttf_#{she_coded_font_size}_normal_normal_normal_left_FFFFFF_2:Nevertheless%252C%0A#{user_name}%20Coded", color: "#FFFFFF", gravity: "west", x: "230", y: "-5", w: "150", bo: "FFFFFF_2" },
    ])
    "#{path}?shecoded&t=#{Time.now.to_i}"
  end

  def discuss_image_path(article)
    if article.comments_count == 0
      comments_string = "New%20discussion%20(0%20responses)"
    else
      comments_string = "#{ActionController::Base.helpers.pluralize(article.comments_count, 'Response')} and counting".gsub(" ","%20")
    end
    "http://res.cloudinary.com/practicaldev/image/upload/c_fit,co_rgb:fcfcfc,h_270,l_text:Montserrat_#{font_size}:#{processed_title},w_810/c_fit,co_rgb:e05252,g_north,h_499,l_text:Roboto%20Mono_50:#{comments_string},w_950,y_400/v1489507069/devdiscuss_base_mvcvmb.png?default&t=#{Time.now.to_i}"
  end

  def selected_tag
    main_tag = OpenStruct.new(bg_color_hex: "#050505", text_color_hex: "#ffffff")
    article.cached_tag_list_array.each do |t|
      tag = Tag.find_by_name(t)
      main_tag = tag if tag && tag.bg_color_hex.present? && tag.text_color_hex.present?
    end
    if found_tag = Tag.find_by_name(article.main_tag_name_for_social)
      if article.cached_tag_list_array.include?(found_tag.name) && found_tag.bg_color_hex.present? && found_tag.text_color_hex.present?
        main_tag = found_tag
      end
    end
    main_tag
  end

  def processed_title
    ERB::Util.url_encode(article.title.gsub(",", "%252C%2520").gsub("/","%2F").gsub(" ","%20")).gsub("%25252C%252520%2520", "%252C%2520")
  end

  def default_social_image(article)
    name = (article.user.text_only_name || article.user.name).titleize
    profile_image_url = if Rails.env.production?
                          article.user.profile_image_url
                        else
                          "https://thepracticaldev.s3.amazonaws.com/uploads/user/profile_image/1075/c097c6cf3c694ac216b084710d06d416.png"
                        end
    text_color = selected_tag.text_color_hex.gsub("#", "")
    bg_color = selected_tag.bg_color_hex.gsub("#", "")
    "http://res.cloudinary.com/practicaldev/image/fetch/bo_4px_solid_rgb:#{text_color},c_scale,w_73/co_rgb:#{bg_color},e_colorize:115,u_dev-social-bg_yaczxp,x_-425,y_-190/c_fit,co_rgb:#{text_color},l_text:Oxygen_#{font_size}_bold:#{processed_title},w_850/co_rgb:#{bg_color},g_north_east,l_text:Patua%20One_34:#{name.gsub(" ","%20")},x_115,y_400,b_rgb:#{text_color},bo_20px_solid_rgb:#{text_color}/c_scale,l_j_dhfgoj_400x400_1_krefkk,w_80,x_-425,y_-190/https://res.cloudinary.com/practicaldev/image/fetch/s--mr1p-SEq--/c_fill,f_auto,fl_progressive,h_220,q_auto,w_220/#{profile_image_url}?default"
  end

  def font_size
    calculated = 93 - (article.title.size / 1.86)
    calculated.to_i
  end
end

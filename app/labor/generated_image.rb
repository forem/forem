class GeneratedImage
  attr_reader :resource

  def initialize(resource)
    @resource = resource
  end

  def social_image
    if resource.class.name.include?("Article")
      article_image
    elsif resource.class.name == "User"
      optimize_image "/user/#{resource.id}?bust=#{resource.profile_image_url}"
    elsif resource.class.name == "Organization"
      optimize_image "/organization/#{resource.id}?bust=#{resource.profile_image_url}"
    elsif resource.class.name.include?("Tag")
      optimize_image "/tag/#{@resource.id}?bust=#{@resource.pretty_name}"
    end
  end

  def article_image
    return resource.social_image if resource.social_image.present?
    return resource.main_image if resource.main_image.present?
    return resource.video_thumbnail_url if resource.video_thumbnail_url.present?

    path = "/article/#{resource.id}?bust=#{resource.comments_count}-#{resource.title}-#{resource.published}"
    optimize_image(path)
  end

  def optimize_image(path)
    options = {
      height: 400,
      width: 800,
      gravity: "north",
      crop: "fill",
      type: "url2png",
      flags: nil,
      quality: nil,
      fetch_format: nil
    }

    Images::Optimizer.call("https://dev.to/social_previews#{path}", options)
  end
end

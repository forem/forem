class GeneratedImage
  include CloudinaryHelper
  attr_reader :resource

  def initialize(resource)
    @resource = resource
  end

  def social_image
    if resource.class.name.include?("Article")
      article_image
    elsif resource.class.name == "User"
      cloudinary_generated_url "/user/#{resource.id}?bust=#{resource.profile_image_url}"
    elsif resource.class.name == "Organization"
      cloudinary_generated_url "/organization/#{resource.id}?bust=#{resource.profile_image_url}"
    elsif resource.class.name.include?("Tag")
      cloudinary_generated_url "/tag/#{@resource.id}?bust=#{@resource.pretty_name}"
    end
  end

  def article_image
    return resource.social_image if resource.social_image.present?
    return resource.main_image if resource.main_image.present?
    return resource.video_thumbnail_url if resource.video_thumbnail_url.present?

    cloudinary_generated_url "/article/#{resource.id}?bust=#{resource.comments_count}-#{resource.title}-#{resource.published}"
  end

  def cloudinary_generated_url(path)
    cl_image_path("https://dev.to/social_previews#{path}",
                  gravity: "north",
                  height: 400,
                  width: 800,
                  crop: "fill",
                  sign_url: true,
                  type: "url2png")
  end
end

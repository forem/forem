class ProfileImage
  BACKUP_LINK = "https://thepracticaldev.s3.amazonaws.com/i/99mvlsfu5tfj9m7ku25d.png".freeze

  attr_accessor :image_link

  def initialize(resource)
    @image_link = resource.profile_image_url
  end

  def get(width: 120)
    Images::Optimizer.call(image_link || BACKUP_LINK, width: width, height: width, crop: "fill")
  end
end

class ProfileSocialImageUploader < BaseUploader
  def store_dir
    "uploads/profile_social_images/"
  end

  def filename
    "#{SecureRandom.uuid}.#{file.extension}" if file.present?
  end
end

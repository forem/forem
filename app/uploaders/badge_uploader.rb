class BadgeUploader < BaseUploader
  def extension_whitelist
    %w[jpg jpeg gif png webp]
  end
end

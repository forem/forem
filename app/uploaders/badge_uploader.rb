class BadgeUploader < BaseUploader
  def extension_allowlist
    %w[jpg jpeg gif png webp]
  end
end

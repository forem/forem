require "open-uri"
class ArticleImageUploader < BaseUploader
  def self.normalize_source_url(raw_url)
    return if raw_url.blank?

    candidate = raw_url.to_s.strip.split(/\s+/, 2).first.to_s.delete_prefix("<").delete_suffix(">")
    return if candidate.blank?

    uri = URI.parse(candidate)
    candidate if uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end

  def store_dir
    "uploads/articles/"
  end

  def filename
    "#{Array.new(20) { rand(36).to_s(36) }.join}.#{file.extension}" if file.present?
  end

  def upload_from_url(url)
    normalized_url = self.class.normalize_source_url(url)
    return unless normalized_url

    # Open the URL and create a temporary file
    file = URI.open(normalized_url) # rubocop:disable Security/Open
    temp_file = Tempfile.new(["upload", File.extname(file.base_uri.path)])
    temp_file.binmode
    temp_file.write(file.read)
    temp_file.rewind

    # Upload the tempfile using CarrierWave
    store!(temp_file)

    # Important: Ensure you return the URL of the uploaded file
    stored_file_url = self.url # This should return the actual URL where the file is stored

    # Cleanup
    temp_file.close
    temp_file.unlink

    stored_file_url
  rescue StandardError => e
    Rails.logger.error "Failed to handle file upload: #{e.message}"
    nil
  end
end

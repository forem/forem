require "open-uri"
class ArticleImageUploader < BaseUploader
  def store_dir
    "uploads/articles/"
  end

  def filename
    "#{Array.new(20) { rand(36).to_s(36) }.join}.#{file.extension}" if original_filename.present?
  end

  def upload_from_url(url)
    # Open the URL and create a temporary file
    file = URI.open(url) # rubocop:disable Security/Open
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

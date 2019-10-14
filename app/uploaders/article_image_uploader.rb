class ArticleImageUploader < BaseUploader
  def store_dir
    "i/"
  end

  def filename
    "#{Array.new(20) { rand(36).to_s(36) }.join}.#{file.extension}" if original_filename.present?
  end
end

class ArticleImageUploader < BaseUploader
  def store_dir
    "uploads/articles/"
  end

  def filename
    "#{Array.new(20) { rand(36).to_s(36) }.join}.#{file.extension}" if original_filename.present?
  end
end

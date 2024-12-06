# Copyright Cloudinary
class Cloudinary::Blob < StringIO
  attr_reader :original_filename, :content_type
  alias_method :path, :original_filename
  
  def initialize(data, options={})
    super(data)
    @original_filename = options[:original_filename] || "cloudinaryfile"
    @content_type = options[:content_type] || "application/octet-stream"
  end
end

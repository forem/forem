# Copyright Cloudinary
# Support for store in CarrierWave files that were preloaded to cloudinary (e.g., by javascript)
# Field value must be in the format:  "image/upload/v<version>/<public_id>.<format>#<signature>"
# Where signature is the cloudinary API signature on the public_id and version.
module Cloudinary::CarrierWave
  PRELOADED_CLOUDINARY_PATH = Cloudinary::PreloadedFile::PRELOADED_CLOUDINARY_PATH
  STORED_CLOUDINARY_PATH = /^([^\/]+)\/([^\/]+)\/v(\d+)\/([^#]+)$/
  SHORT_STORED_CLOUDINARY_PATH = /^v(\d+)\/([^#]+)$/

  def cache!(new_file)
    file = Cloudinary::CarrierWave::createRawOrPreloaded(new_file)
    if file
      @file = file
      @stored_version = @file.version
      @public_id = @stored_public_id = @file.public_id
      self.original_filename = sanitize(@file.original_filename)
      @cache_id = "unused" # must not be blank 
    else
      super
      @public_id = nil # allow overriding public_id
    end
  end

  def retrieve_from_cache!(new_file)
    file = Cloudinary::CarrierWave::createRawOrPreloaded(new_file)
    if file
      @file = file
      @stored_version = @file.version
      @public_id = @stored_public_id = @file.public_id
      self.original_filename = sanitize(@file.original_filename)
      @cache_id = "unused" # must not be blank 
    else
      super
      @public_id = nil # allow overriding public_id
    end
  end
  
  def cache_name
    return (@file.is_a?(PreloadedCloudinaryFile) || @file.is_a?(StoredFile)) ? @file.to_s : super
  end
  
  class PreloadedCloudinaryFile < Cloudinary::PreloadedFile
    def initialize(file_info)
      super
      if !valid?
        raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.cloudinary_signature_error", :public_id=>public_id, :default=>"Invalid signature for #{public_id}")
      end
    end    

    def delete
      # Do nothing. This is a virtual file.
    end
    
    def original_filename
      self.filename
    end
  end
  
  class StoredFile < Cloudinary::PreloadedFile
    def initialize(file_info)
      if file_info.match(STORED_CLOUDINARY_PATH)
        @resource_type, @type, @version, @filename = file_info.scan(STORED_CLOUDINARY_PATH).first 
      elsif file_info.match(SHORT_STORED_CLOUDINARY_PATH)
        @version, @filename = file_info.scan(SHORT_STORED_CLOUDINARY_PATH).first
      else
        raise(ArgumentError, "File #{file_info} is illegal") 
      end
      @public_id, @format = Cloudinary::PreloadedFile.split_format(@filename)
    end
  
    def valid?
      true
    end

    def delete
      # Do nothing. This is a virtual file.
    end

    def original_filename
      self.filename
    end
    
    def to_s
      identifier
    end
  end
  
  def self.createRawOrPreloaded(file)
    return file if file.is_a?(Cloudinary::CarrierWave::StoredFile)
    return PreloadedCloudinaryFile.new(file) if file.is_a?(String) && file.match(PRELOADED_CLOUDINARY_PATH)
    nil
  end
end

class Cloudinary::PreloadedFile
  PRELOADED_CLOUDINARY_PATH = /^([^\/]+)\/([^\/]+)\/v(\d+)\/([^#]+)#([^\/]+)$/

  attr_reader :filename, :version, :public_id, :signature, :resource_type, :type, :format
  def initialize(file_info)
    @resource_type, @type, @version, @filename, @signature = file_info.scan(PRELOADED_CLOUDINARY_PATH).first    
    @public_id, @format = Cloudinary::PreloadedFile.split_format(@filename)      
  end
  
  def valid?
    public_id = @resource_type == "raw" ? self.filename : self.public_id
    expected_signature = Cloudinary::Utils.api_sign_request({:public_id=>public_id, :version=>version}, Cloudinary.config.api_secret)
    @signature == expected_signature
  end
  
  def identifier
    "v#{version}/#{filename}"
  end
  
  def to_s
    "#{resource_type}/#{type}/v#{version}/#{filename}##{signature}"
  end

  def self.split_format(identifier)
    last_dot = identifier.rindex(".")
    return [identifier, nil] if last_dot.nil?
    public_id = identifier[0, last_dot]
    format = identifier[last_dot+1..-1]
    return [public_id, format]    
  end
  
end

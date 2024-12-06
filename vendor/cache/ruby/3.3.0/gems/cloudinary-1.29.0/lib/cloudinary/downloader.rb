# Copyright Cloudinary
class Cloudinary::Downloader
  
  def self.download(source, options={})
    options = options.clone

    if !source.match(/^https?:\/\//i)
      source = Cloudinary::Utils.cloudinary_url(source, options)      
    end


    url = URI.parse(source)
    http = Net::HTTP.new(url.host, url.port)
    req = Net::HTTP::Get.new(url.request_uri)

    if url.port == 443
      http.use_ssl=true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end  
    
    res = http.start{|agent| 
      agent.request(req)
    }

    return res.body
  end
    
end

module Images
  module Profile
    # A convenience module for wrapping the Profile::Images logic.
    #
    # @param attribute [Symbol] named attribute that is an image_url
    #
    # @return [Module] for inclusion into the given class
    #
    # @example
    #   class User
    #     include Images::Profile.for(:image_url)
    #   end
    def self.for(attribute)
      Module.new do
        define_method("#{attribute}_for") do |length:|
          Images::Profile.call(public_send(attribute), length: length)
        end
      end
    end
    BACKUP_LINK = "https://thepracticaldev.s3.amazonaws.com/i/99mvlsfu5tfj9m7ku25d.png".freeze

    def self.call(image_url, length: 120)
      Optimizer.call(
        image_url || BACKUP_LINK,
        width: length,
        height: length,
        crop: "crop",
        never_imagga: true,
      )
    end
  end
end

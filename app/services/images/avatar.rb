module Images
  module Avatar
    BACKUP_LINK = "https://thepracticaldev.s3.amazonaws.com/i/99mvlsfu5tfj9m7ku25d.png".freeze

    def self.call(image_url = BACKUP_LINK, length: 120)
      Optimizer.call(image_url, width: length, height: length, crop: "fill")
    end
  end
end

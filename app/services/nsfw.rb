require "nsfw"

module Nsfw
  SAFETY_THRESHOLD = 0.7
  PORN_THRESHOLD = 0.65
  HENTAI_THRESHOLD = 0.6 

  class NsfwEroticError < StandardError
    def initialize(msg="Erotic content")
      super
    end
  end

  class NsfwHentaiError < StandardError
    def initialize(msg="Hentai content")
      super
    end
  end

  def self.safe?(image_path)
    if !File.file?(image_path)
      raise Exception.new "Image file does not exists"
    end

    predictions = NSFW::Image.predictions(image_path)

    if predictions["porn"] >= PORN_THRESHOLD
      raise NsfwEroticError.new
    end

    if predictions["hentai"] >= HENTAI_THRESHOLD
      raise NsfwHentaiError.new
    end

    return predictions["neutral"] >= SAFETY_THRESHOLD
  end

  def self.unsafe?(image_path)
    !self.safe?(image_path)
  end
end

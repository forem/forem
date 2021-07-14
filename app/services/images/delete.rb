# app/services/images/delete.rb

module Images
  class Delete
    attr_accessor :image_path

    def initialize(image_path)
      @image_path = image_path
    end

    def self.call(...)
      new(...).call
    end

    def call
      uploader = ArticleImageUploader.new
      return if image_path.blank?

      uploader.retrieve_from_store!(image_path)
      uploader.remove!
    end
  end
end

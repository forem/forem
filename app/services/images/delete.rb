# app/services/images/delete.rb

module Images
  class Delete
    attr_accessor :image_paths

    def initialize(image_paths)
      @image_paths = image_paths
    end

    def self.call(...)
      new(...).call
    end

    def call
      uploader = ArticleImageUploader.new
      image_paths.each do |image_path|
        uploader.retrieve_from_store!(image_path)
        uploader.remove!
      end
    end
  end
end

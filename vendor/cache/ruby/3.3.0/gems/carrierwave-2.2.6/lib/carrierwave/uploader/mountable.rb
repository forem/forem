module CarrierWave
  module Uploader
    module Mountable

      attr_reader :model, :mounted_as

      ##
      # If a model is given as the first parameter, it will be stored in the
      # uploader, and available through +#model+. Likewise, mounted_as stores
      # the name of the column where this instance of the uploader is mounted.
      # These values can then be used inside your uploader.
      #
      # If you do not wish to mount your uploaders with the ORM extensions in
      # -more then you can override this method inside your uploader. Just be
      # sure to call +super+
      #
      # === Parameters
      #
      # [model (Object)] Any kind of model object
      # [mounted_as (Symbol)] The name of the column where this uploader is mounted
      #
      # === Examples
      #
      #     class MyUploader < CarrierWave::Uploader::Base
      #
      #       def store_dir
      #         File.join('public', 'files', mounted_as, model.permalink)
      #       end
      #     end
      #
      def initialize(model=nil, mounted_as=nil)
        @model = model
        @mounted_as = mounted_as
      end

      ##
      # Returns array index of given uploader within currently mounted uploaders
      #
      def index
        model.__send__(:_mounter, mounted_as).uploaders.index(self)
      end
    end # Mountable
  end # Uploader
end # CarrierWave

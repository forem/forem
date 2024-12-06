module CarrierWave
  module Storage

    ##
    # This file serves mostly as a specification for Storage engines. There is no requirement
    # that storage engines must be a subclass of this class.
    #
    class Abstract

      attr_reader :uploader

      def initialize(uploader)
        @uploader = uploader
      end

      def identifier
        uploader.filename
      end

      def store!(file)
      end

      def retrieve!(identifier)
      end

      def cache!(new_file)
        raise NotImplementedError.new("Need to implement #cache! if you want to use #{self.class.name} as a cache storage.")
      end

      def retrieve_from_cache!(identifier)
        raise NotImplementedError.new("Need to implement #retrieve_from_cache! if you want to use #{self.class.name} as a cache storage.")
      end

      def delete_dir!(path)
        raise NotImplementedError.new("Need to implement #delete_dir! if you want to use #{self.class.name} as a cache storage.")
      end

      def clean_cache!(seconds)
        raise NotImplementedError.new("Need to implement #clean_cache! if you want to use #{self.class.name} as a cache storage.")
      end
    end # Abstract
  end # Storage
end # CarrierWave

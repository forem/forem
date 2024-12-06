module CarrierWave
  module Uploader
    module Processing
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks

      included do
        class_attribute :processors, :instance_writer => false
        self.processors = []

        before :cache, :process!
      end

      module ClassMethods

        ##
        # Adds a processor callback which applies operations as a file is uploaded.
        # The argument may be the name of any method of the uploader, expressed as a symbol,
        # or a list of such methods, or a hash where the key is a method and the value is
        # an array of arguments to call the method with
        #
        # === Parameters
        #
        # args (*Symbol, Hash{Symbol => Array[]})
        #
        # === Examples
        #
        #     class MyUploader < CarrierWave::Uploader::Base
        #
        #       process :sepiatone, :vignette
        #       process :scale => [200, 200]
        #       process :scale => [200, 200], :if => :image?
        #       process :sepiatone, :if => :image?
        #
        #       def sepiatone
        #         ...
        #       end
        #
        #       def vignette
        #         ...
        #       end
        #
        #       def scale(height, width)
        #         ...
        #       end
        #
        #       def image?
        #         ...
        #       end
        #
        #     end
        #
        def process(*args)
          new_processors = args.inject({}) do |hash, arg|
            arg = { arg => [] } unless arg.is_a?(Hash)
            hash.merge!(arg)
          end

          condition = new_processors.delete(:if)
          new_processors.each do |processor, processor_args|
            self.processors += [[processor, processor_args, condition]]
          end
        end

      end # ClassMethods

      ##
      # Apply all process callbacks added through CarrierWave.process
      #
      def process!(new_file=nil)
        return unless enable_processing

        with_callbacks(:process, new_file) do
          self.class.processors.each do |method, args, condition|
            if(condition)
              if condition.respond_to?(:call)
                next unless condition.call(self, :args => args, :method => method, :file => new_file)
              else
                next unless self.send(condition, new_file)
              end
            end

            if args.is_a? Array
              kwargs, args = args.partition { |arg| arg.is_a? Hash }
            end

            if kwargs.present?
              kwargs = kwargs.reduce(:merge)
              self.send(method, *args, **kwargs)
            else
              self.send(method, *args)
            end
          end
        end
      end

    end # Processing
  end # Uploader
end # CarrierWave

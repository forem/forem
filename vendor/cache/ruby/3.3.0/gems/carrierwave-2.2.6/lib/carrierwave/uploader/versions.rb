module CarrierWave
  module Uploader
    module Versions
      extend ActiveSupport::Concern

      include CarrierWave::Uploader::Callbacks

      included do
        class_attribute :versions, :version_names, :version_options, :instance_reader => false, :instance_writer => false

        self.versions = {}
        self.version_names = []

        attr_accessor :parent_cache_id, :parent_version

        after :cache, :assign_parent_cache_id
        after :cache, :cache_versions!
        after :store, :store_versions!
        after :remove, :remove_versions!
        after :retrieve_from_cache, :retrieve_versions_from_cache!
        after :retrieve_from_store, :retrieve_versions_from_store!

        prepend Module.new {
          def initialize(*)
            super
            @versions, @versions_to_cache, @versions_to_store = nil
          end
        }
      end

      module ClassMethods

        ##
        # Adds a new version to this uploader
        #
        # === Parameters
        #
        # [name (#to_sym)] name of the version
        # [options (Hash)] optional options hash
        # [&block (Proc)] a block to eval on this version of the uploader
        #
        # === Examples
        #
        #     class MyUploader < CarrierWave::Uploader::Base
        #
        #       version :thumb do
        #         process :scale => [200, 200]
        #       end
        #
        #       version :preview, :if => :image? do
        #         process :scale => [200, 200]
        #       end
        #
        #     end
        #
        def version(name, options = {}, &block)
          name = name.to_sym
          build_version(name, options)

          versions[name].class_eval(&block) if block
          versions[name]
        end

        def recursively_apply_block_to_versions(&block)
          versions.each do |name, version|
            version.class_eval(&block)
            version.recursively_apply_block_to_versions(&block)
          end
        end

      private

        def build_version(name, options)
          if !versions.has_key?(name)
            uploader = Class.new(self)
            const_set("Uploader#{uploader.object_id}".tr('-', '_'), uploader)
            uploader.version_names += [name]
            uploader.versions = {}
            uploader.processors = []
            uploader.version_options = options

            uploader.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              # Define the enable_processing method for versions so they get the
              # value from the parent class unless explicitly overwritten
              def self.enable_processing(value=nil)
                self.enable_processing = value if value
                if defined?(@enable_processing) && !@enable_processing.nil?
                  @enable_processing
                else
                  superclass.enable_processing
                end
              end

              # Regardless of what is set in the parent uploader, do not enforce the
              # move_to_cache config option on versions because it moves the original
              # file to the version's target file.
              #
              # If you want to enforce this setting on versions, override this method
              # in each version:
              #
              # version :thumb do
              #   def move_to_cache
              #     true
              #   end
              # end
              #
              def move_to_cache
                false
              end
            RUBY

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{name}
                versions[:#{name}]
              end
            RUBY
          else
            uploader = Class.new(versions[name])
            const_set("Uploader#{uploader.object_id}".tr('-', '_'), uploader)
            uploader.processors = []
            uploader.version_options = uploader.version_options.merge(options)
          end

          # Add the current version hash to class attribute :versions
          self.versions = versions.merge(name => uploader)
        end

      end # ClassMethods

      ##
      # Returns a hash mapping the name of each version of the uploader to an instance of it
      #
      # === Returns
      #
      # [Hash{Symbol => CarrierWave::Uploader}] a list of uploader instances
      #
      def versions
        return @versions if @versions
        @versions = {}
        self.class.versions.each do |name, version|
          @versions[name] = version.new(model, mounted_as)
          @versions[name].parent_version = self
        end
        @versions
      end

      ##
      # === Returns
      #
      # [String] the name of this version of the uploader
      #
      def version_name
        self.class.version_names.join('_').to_sym unless self.class.version_names.blank?
      end

      ##
      #
      # === Parameters
      #
      # [name (#to_sym)] name of the version
      #
      # === Returns
      #
      # [Boolean] True when the version exists according to its :if condition
      #
      def version_exists?(name)
        name = name.to_sym

        return false unless self.class.versions.has_key?(name)

        condition = self.class.versions[name].version_options[:if]
        if(condition)
          if(condition.respond_to?(:call))
            condition.call(self, :version => name, :file => file)
          else
            send(condition, file)
          end
        else
          true
        end
      end

      ##
      # When given a version name as a parameter, will return the url for that version
      # This also works with nested versions.
      # When given a query hash as a parameter, will return the url with signature that contains query params
      # Query hash only works with AWS (S3 storage).
      #
      # === Example
      #
      #     my_uploader.url                 # => /path/to/my/uploader.gif
      #     my_uploader.url(:thumb)         # => /path/to/my/thumb_uploader.gif
      #     my_uploader.url(:thumb, :small) # => /path/to/my/thumb_small_uploader.gif
      #     my_uploader.url(:query => {"response-content-disposition" => "attachment"})
      #     my_uploader.url(:version, :sub_version, :query => {"response-content-disposition" => "attachment"})
      #
      # === Parameters
      #
      # [*args (Symbol)] any number of versions
      # OR/AND
      # [Hash] query params
      #
      # === Returns
      #
      # [String] the location where this file is accessible via a url
      #
      def url(*args)
        if (version = args.first) && version.respond_to?(:to_sym)
          raise ArgumentError, "Version #{version} doesn't exist!" if versions[version.to_sym].nil?
          # recursively proxy to version
          versions[version.to_sym].url(*args[1..-1])
        elsif args.first
          super(args.first)
        else
          super
        end
      end

      ##
      # Recreate versions and reprocess them. This can be used to recreate
      # versions if their parameters somehow have changed.
      #
      def recreate_versions!(*names)
        # Some files could possibly not be stored on the local disk. This
        # doesn't play nicely with processing. Make sure that we're only
        # processing a cached file
        #
        # The call to store! will trigger the necessary callbacks to both
        # process this version and all sub-versions

        if names.any?
          set_versions_to_cache_and_store(names)
          store!(file)
          reset_versions_to_cache_and_store
        else
          cache! if !cached?
          store!
        end
      end

    private

      def set_versions_to_cache_and_store(names)
        @versions_to_cache = source_versions_of(names)
        @versions_to_store = active_versions_with_names_in(@versions_to_cache + names)
      end

      def reset_versions_to_cache_and_store
        @versions_to_cache, @versions_to_store = nil, nil
      end

      def versions_to_cache
        @versions_to_cache || dependent_versions
      end

      def versions_to_store
        @versions_to_store || active_versions
      end

      def source_versions_of(requested_names)
        versions.inject([]) do |sources, (name, uploader)|
          next sources unless requested_names.include?(name)
          next sources unless source_name = uploader.class.version_options[:from_version]

          sources << [source_name, versions[source_name]]
        end.uniq
      end

      def active_versions_with_names_in(names)
        active_versions.select do |pretendent_name, uploader|
          names.include?(pretendent_name)
        end
      end

      def assign_parent_cache_id(file)
        active_versions.each do |name, uploader|
          uploader.parent_cache_id = @cache_id
        end
      end

      def active_versions
        versions.select do |name, uploader|
          version_exists?(name)
        end
      end

      def dependent_versions
        active_versions.reject do |name, v|
          v.class.version_options[:from_version]
        end.to_a + sibling_versions.select do |name, v|
          v.class.version_options[:from_version] == self.class.version_names.last
        end.to_a
      end

      def sibling_versions
        parent_version.try(:versions) || []
      end

      def full_filename(for_file)
        [version_name, super(for_file)].compact.join('_')
      end

      def full_original_filename
        [version_name, super].compact.join('_')
      end

      def cache_versions!(new_file)
        versions_to_cache.each do |name, v|
          v.send(:cache_id=, @cache_id)
          v.cache!(new_file)
        end
      end

      def store_versions!(new_file)
        versions_to_store.each { |name, v| v.store!(new_file) }
      end

      def remove_versions!
        versions.each { |name, v| v.remove! }
      end

      def retrieve_versions_from_cache!(cache_name)
        active_versions.each { |name, v| v.retrieve_from_cache!(cache_name) }
      end

      def retrieve_versions_from_store!(identifier)
        active_versions.each { |name, v| v.retrieve_from_store!(identifier) }
      end

    end # Versions
  end # Uploader
end # CarrierWave

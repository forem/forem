require 'carrierwave/downloader/base'

module CarrierWave

  module Uploader
    module Configuration
      extend ActiveSupport::Concern

      included do
        class_attribute :_storage, :_cache_storage, :instance_writer => false

        add_config :root
        add_config :base_path
        add_config :asset_host
        add_config :permissions
        add_config :directory_permissions
        add_config :storage_engines
        add_config :store_dir
        add_config :cache_dir
        add_config :enable_processing
        add_config :ensure_multipart_form
        add_config :delete_tmp_file_after_storage
        add_config :move_to_cache
        add_config :move_to_store
        add_config :remove_previously_stored_files_after_update
        add_config :downloader

        # fog
        add_deprecated_config :fog_provider
        add_config :fog_attributes
        add_config :fog_credentials
        add_config :fog_directory
        add_config :fog_public
        add_config :fog_authenticated_url_expiration
        add_config :fog_use_ssl_for_aws
        add_config :fog_aws_accelerate

        # Mounting
        add_config :ignore_integrity_errors
        add_config :ignore_processing_errors
        add_config :ignore_download_errors
        add_config :validate_integrity
        add_config :validate_processing
        add_config :validate_download
        add_config :mount_on
        add_config :cache_only

        # set default values
        reset_config
      end

      module ClassMethods

        ##
        # Sets the storage engine to be used when storing files with this uploader.
        # Can be any class that implements a #store!(CarrierWave::SanitizedFile) and a #retrieve!
        # method. See lib/carrierwave/storage/file.rb for an example. Storage engines should
        # be added to CarrierWave::Uploader::Base.storage_engines so they can be referred
        # to by a symbol, which should be more convenient
        #
        # If no argument is given, it will simply return the currently used storage engine.
        #
        # === Parameters
        #
        # [storage (Symbol, Class)] The storage engine to use for this uploader
        #
        # === Returns
        #
        # [Class] the storage engine to be used with this uploader
        #
        # === Examples
        #
        #     storage :file
        #     storage CarrierWave::Storage::File
        #     storage MyCustomStorageEngine
        #
        def storage(storage = nil)
          case storage
          when Symbol
            if storage_engine = storage_engines[storage]
              self._storage = eval storage_engine
            else
              raise CarrierWave::UnknownStorageError, "Unknown storage: #{storage}"
            end
          when nil
            storage
          else
            self._storage = storage
          end
          _storage
        end
        alias_method :storage=, :storage

        ##
        # Sets the cache storage engine to be used when storing cache files with this uploader.
        # Same as .storage except for required methods being #cache!(CarrierWave::SanitizedFile),
        # #retrieve_from_cache! and #delete_dir!.
        #
        # === Parameters
        #
        # [storage (Symbol, Class)] The cache storage engine to use for this uploader
        #
        # === Returns
        #
        # [Class] the cache storage engine to be used with this uploader
        #
        # === Examples
        #
        #     cache_storage :file
        #     cache_storage CarrierWave::Storage::File
        #     cache_storage MyCustomStorageEngine
        #
        def cache_storage(storage = false)
          unless storage == false
            self._cache_storage = storage.is_a?(Symbol) ? eval(storage_engines[storage]) : storage
          end
          _cache_storage
        end
        alias_method :cache_storage=, :cache_storage

        def add_config(name)
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            @#{name} = nil

            def self.#{name}(value=nil)
              @#{name} = value if value
              return @#{name} if self.object_id == #{self.object_id} || defined?(@#{name})
              name = superclass.#{name}
              return nil if name.nil? && !instance_variable_defined?(:@#{name})
              @#{name} = name && !name.is_a?(Module) && !name.is_a?(Symbol) && !name.is_a?(Numeric) && !name.is_a?(TrueClass) && !name.is_a?(FalseClass) ? name.dup : name
            end

            def self.#{name}=(value)
              @#{name} = value
            end

            def #{name}=(value)
              @#{name} = value
            end

            def #{name}
              value = @#{name} if instance_variable_defined?(:@#{name})
              value = self.class.#{name} unless instance_variable_defined?(:@#{name})
              if value.instance_of?(Proc)
                value.arity >= 1 ? value.call(self) : value.call
              else
                value
              end
            end
          RUBY
        end

        def add_deprecated_config(name)
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def self.#{name}(value=nil)
              ActiveSupport::Deprecation.warn "##{name} is deprecated and has no effect"
            end

            def self.#{name}=(value)
              ActiveSupport::Deprecation.warn "##{name} is deprecated and has no effect"
            end

            def #{name}=(value)
              ActiveSupport::Deprecation.warn "##{name} is deprecated and has no effect"
            end

            def #{name}
              ActiveSupport::Deprecation.warn "##{name} is deprecated and has no effect"
            end
          RUBY
        end

        def configure
          yield self
        end

        ##
        # sets configuration back to default
        #
        def reset_config
          configure do |config|
            config.permissions = 0644
            config.directory_permissions = 0755
            config.storage_engines = {
              :file => "CarrierWave::Storage::File",
              :fog  => "CarrierWave::Storage::Fog"
            }
            config.storage = :file
            config.cache_storage = nil
            config.fog_attributes = {}
            config.fog_credentials = {}
            config.fog_public = true
            config.fog_authenticated_url_expiration = 600
            config.fog_use_ssl_for_aws = true
            config.fog_aws_accelerate = false
            config.store_dir = 'uploads'
            config.cache_dir = 'uploads/tmp'
            config.delete_tmp_file_after_storage = true
            config.move_to_cache = false
            config.move_to_store = false
            config.remove_previously_stored_files_after_update = true
            config.downloader = CarrierWave::Downloader::Base
            config.ignore_integrity_errors = true
            config.ignore_processing_errors = true
            config.ignore_download_errors = true
            config.validate_integrity = true
            config.validate_processing = true
            config.validate_download = true
            config.root = lambda { CarrierWave.root }
            config.base_path = CarrierWave.base_path
            config.enable_processing = true
            config.ensure_multipart_form = true
          end
        end
      end

    end
  end
end

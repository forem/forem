module CarrierWave
  module Storage

    ##
    # File storage stores file to the Filesystem (surprising, no?). There's really not much
    # to it, it uses the store_dir defined on the uploader as the storage location. That's
    # pretty much it.
    #
    class File < Abstract
      def initialize(*)
        super
        @cache_called = nil
      end

      ##
      # Move the file to the uploader's store path.
      #
      # By default, store!() uses copy_to(), which operates by copying the file
      # from the cache to the store, then deleting the file from the cache.
      # If move_to_store() is overriden to return true, then store!() uses move_to(),
      # which simply moves the file from cache to store.  Useful for large files.
      #
      # === Parameters
      #
      # [file (CarrierWave::SanitizedFile)] the file to store
      #
      # === Returns
      #
      # [CarrierWave::SanitizedFile] a sanitized file
      #
      def store!(file)
        path = ::File.expand_path(uploader.store_path, uploader.root)
        if uploader.move_to_store
          file.move_to(path, uploader.permissions, uploader.directory_permissions)
        else
          file.copy_to(path, uploader.permissions, uploader.directory_permissions)
        end
      end

      ##
      # Retrieve the file from its store path
      #
      # === Parameters
      #
      # [identifier (String)] the filename of the file
      #
      # === Returns
      #
      # [CarrierWave::SanitizedFile] a sanitized file
      #
      def retrieve!(identifier)
        path = ::File.expand_path(uploader.store_path(identifier), uploader.root)
        CarrierWave::SanitizedFile.new(path)
      end

      ##
      # Stores given file to cache directory.
      #
      # === Parameters
      #
      # [new_file (File, IOString, Tempfile)] any kind of file object
      #
      # === Returns
      #
      # [CarrierWave::SanitizedFile] a sanitized file
      #
      def cache!(new_file)
        new_file.move_to(::File.expand_path(uploader.cache_path, uploader.root), uploader.permissions, uploader.directory_permissions, true)
      rescue Errno::EMLINK, Errno::ENOSPC => e
        raise(e) if @cache_called
        @cache_called = true

        # NOTE: Remove cached files older than 10 minutes
        clean_cache!(600)

        cache!(new_file)
      end

      ##
      # Retrieves the file with the given cache_name from the cache.
      #
      # === Parameters
      #
      # [cache_name (String)] uniquely identifies a cache file
      #
      # === Raises
      #
      # [CarrierWave::InvalidParameter] if the cache_name is incorrectly formatted.
      #
      def retrieve_from_cache!(identifier)
        CarrierWave::SanitizedFile.new(::File.expand_path(uploader.cache_path(identifier), uploader.root))
      end

      ##
      # Deletes a cache dir
      #
      def delete_dir!(path)
        if path
          begin
            Dir.rmdir(::File.expand_path(path, uploader.root))
          rescue Errno::ENOENT
            # Ignore: path does not exist
          rescue Errno::ENOTDIR
            # Ignore: path is not a dir
          rescue Errno::ENOTEMPTY, Errno::EEXIST
            # Ignore: dir is not empty
          end
        end
      end

      def clean_cache!(seconds)
        Dir.glob(::File.expand_path(::File.join(uploader.cache_dir, '*'), CarrierWave.root)).each do |dir|
          # generate_cache_id returns key formated TIMEINT-PID(-COUNTER)-RND
          time = dir.scan(/(\d+)-\d+-\d+(?:-\d+)?/).first.map(&:to_i)
          time = Time.at(*time)
          if time < (Time.now.utc - seconds)
            FileUtils.rm_rf(dir)
          end
        end
      end
    end # File
  end # Storage
end # CarrierWave

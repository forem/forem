module CarrierWave

  ##
  # If a Class is extended with this module, it gains the mount_uploader
  # method, which is used for mapping attributes to uploaders and allowing
  # easy assignment.
  #
  # You can use mount_uploader with pretty much any class, however it is
  # intended to be used with some kind of persistent storage, like an ORM.
  # If you want to persist the uploaded files in a particular Class, it
  # needs to implement a `read_uploader` and a `write_uploader` method.
  #
  module Mount

    ##
    # === Returns
    #
    # [Hash{Symbol => CarrierWave}] what uploaders are mounted on which columns
    #
    def uploaders
      @uploaders ||= superclass.respond_to?(:uploaders) ? superclass.uploaders.dup : {}
    end

    def uploader_options
      @uploader_options ||= superclass.respond_to?(:uploader_options) ? superclass.uploader_options.dup : {}
    end

    ##
    # Return a particular option for a particular uploader
    #
    # === Parameters
    #
    # [column (Symbol)] The column the uploader is mounted at
    # [option (Symbol)] The option, e.g. validate_integrity
    #
    # === Returns
    #
    # [Object] The option value
    #
    def uploader_option(column, option)
      if uploader_options[column].has_key?(option)
        uploader_options[column][option]
      else
        uploaders[column].send(option)
      end
    end

    ##
    # Mounts the given uploader on the given column. This means that assigning
    # and reading from the column will upload and retrieve files. Supposing
    # that a User class has an uploader mounted on image, you can assign and
    # retrieve files like this:
    #
    #     @user.image # => <Uploader>
    #     @user.image.store!(some_file_object)
    #
    #     @user.image.url # => '/some_url.png'
    #
    # It is also possible (but not recommended) to omit the uploader, which
    # will create an anonymous uploader class.
    #
    # Passing a block makes it possible to customize the uploader. This can be
    # convenient for brevity, but if there is any significant logic in the
    # uploader, you should do the right thing and have it in its own file.
    #
    # === Added instance methods
    #
    # Supposing a class has used +mount_uploader+ to mount an uploader on a column
    # named +image+, in that case the following methods will be added to the class:
    #
    # [image]                   Returns an instance of the uploader only if anything has been uploaded
    # [image=]                  Caches the given file
    #
    # [image_url]               Returns the url to the uploaded file
    #
    # [image_cache]             Returns a string that identifies the cache location of the file
    # [image_cache=]            Retrieves the file from the cache based on the given cache name
    #
    # [remote_image_url]        Returns previously cached remote url
    # [remote_image_url=]       Retrieve the file from the remote url
    #
    # [remove_image]            An attribute reader that can be used with a checkbox to mark a file for removal
    # [remove_image=]           An attribute writer that can be used with a checkbox to mark a file for removal
    # [remove_image?]           Whether the file should be removed when store_image! is called.
    #
    # [store_image!]            Stores a file that has been assigned with +image=+
    # [remove_image!]           Removes the uploaded file from the filesystem.
    #
    # [image_integrity_error]   Returns an error object if the last file to be assigned caused an integrity error
    # [image_processing_error]  Returns an error object if the last file to be assigned caused a processing error
    # [image_download_error]    Returns an error object if the last file to be remotely assigned caused a download error
    #
    # [image_identifier]        Reads out the identifier of the file
    #
    # === Parameters
    #
    # [column (Symbol)]                   the attribute to mount this uploader on
    # [uploader (CarrierWave::Uploader)]  the uploader class to mount
    # [options (Hash{Symbol => Object})]  a set of options
    # [&block (Proc)]                     customize anonymous uploaders
    #
    # === Options
    #
    # [:mount_on => Symbol] if the name of the column to be serialized to differs you can override it using this option
    # [:ignore_integrity_errors => Boolean] if set to true, integrity errors will result in caching failing silently
    # [:ignore_processing_errors => Boolean] if set to true, processing errors will result in caching failing silently
    #
    # === Examples
    #
    # Mounting uploaders on different columns.
    #
    #     class Song
    #       mount_uploader :lyrics, LyricsUploader
    #       mount_uploader :alternative_lyrics, LyricsUploader
    #       mount_uploader :file, SongUploader
    #     end
    #
    # This will add an anonymous uploader with only the default settings:
    #
    #     class Data
    #       mount_uploader :csv
    #     end
    #
    # this will add an anonymous uploader overriding the store_dir:
    #
    #     class Product
    #       mount_uploader :blueprint do
    #         def store_dir
    #           'blueprints'
    #         end
    #       end
    #     end
    #
    def mount_uploader(column, uploader=nil, options={}, &block)
      mount_base(column, uploader, options, &block)

      mod = Module.new
      include mod
      mod.class_eval <<-RUBY, __FILE__, __LINE__+1

        def #{column}
          _mounter(:#{column}).uploaders[0] ||= _mounter(:#{column}).blank_uploader
        end

        def #{column}=(new_file)
          _mounter(:#{column}).cache([new_file])
        end

        def #{column}_url(*args)
          #{column}.url(*args)
        end

        def #{column}_cache
          _mounter(:#{column}).cache_names[0]
        end

        def #{column}_cache=(cache_name)
          _mounter(:#{column}).cache_names = [cache_name]
        end

        def remote_#{column}_url
          [_mounter(:#{column}).remote_urls].flatten[0]
        end

        def remote_#{column}_url=(url)
          _mounter(:#{column}).remote_urls = [url]
        end

        def remote_#{column}_request_header=(header)
          _mounter(:#{column}).remote_request_headers = [header]
        end

        def write_#{column}_identifier
          return if frozen?
          mounter = _mounter(:#{column})

          mounter.clear! if mounter.remove?
          write_uploader(mounter.serialization_column, mounter.identifiers.first)
        end

        def #{column}_identifier
          _mounter(:#{column}).read_identifiers[0]
        end

        def #{column}_integrity_error
          #{column}_integrity_errors.last
        end

        def #{column}_processing_error
          #{column}_processing_errors.last
        end

        def #{column}_download_error
          #{column}_download_errors.last
        end

        def store_previous_changes_for_#{column}
          attribute_changes = ::ActiveRecord.version.to_s.to_f >= 5.1 ? saved_changes : changes
          @_previous_changes_for_#{column} = attribute_changes[_mounter(:#{column}).serialization_column]
        end

        def remove_previously_stored_#{column}
          before, after = @_previous_changes_for_#{column}
          _mounter(:#{column}).remove_previous([before], [after])
        end
      RUBY
    end

    ##
    # Mounts the given uploader on the given array column. This means that
    # assigning and reading from the array column will upload and retrieve
    # multiple files. Supposing that a User class has an uploader mounted on
    # images, and that images can store an array, for example it could be a
    # PostgreSQL JSON column. You can assign and retrieve files like this:
    #
    #     @user.images # => []
    #     @user.images = [some_file_object]
    #     @user.images # => [<Uploader>]
    #
    #     @user.images[0].url # => '/some_url.png'
    #
    # It is also possible (but not recommended) to omit the uploader, which
    # will create an anonymous uploader class.
    #
    # Passing a block makes it possible to customize the uploader. This can be
    # convenient for brevity, but if there is any significant logic in the
    # uploader, you should do the right thing and have it in its own file.
    #
    # === Added instance methods
    #
    # Supposing a class has used +mount_uploaders+ to mount an uploader on a column
    # named +images+, in that case the following methods will be added to the class:
    #
    # [images]                  Returns an array of uploaders for each uploaded file
    # [images=]                 Caches the given files
    #
    # [images_urls]             Returns the urls to the uploaded files
    #
    # [images_cache]            Returns a string that identifies the cache location of the files
    # [images_cache=]           Retrieves the files from the cache based on the given cache name
    #
    # [remote_image_urls]       Returns previously cached remote urls
    # [remote_image_urls=]      Retrieve files from the given remote urls
    #
    # [remove_images]           An attribute reader that can be used with a checkbox to mark the files for removal
    # [remove_images=]          An attribute writer that can be used with a checkbox to mark the files for removal
    # [remove_images?]          Whether the files should be removed when store_image! is called.
    #
    # [store_images!]           Stores all files that have been assigned with +images=+
    # [remove_images!]          Removes the uploaded file from the filesystem.
    #
    # [image_integrity_errors]   Returns error objects of files which failed to pass integrity check
    # [image_processing_errors]  Returns error objects of files which failed to be processed
    # [image_download_errors]    Returns error objects of files which failed to be downloaded
    #
    # [image_identifiers]       Reads out the identifiers of the files
    #
    # === Parameters
    #
    # [column (Symbol)]                   the attribute to mount this uploader on
    # [uploader (CarrierWave::Uploader)]  the uploader class to mount
    # [options (Hash{Symbol => Object})]  a set of options
    # [&block (Proc)]                     customize anonymous uploaders
    #
    # === Options
    #
    # [:mount_on => Symbol] if the name of the column to be serialized to differs you can override it using this option
    # [:ignore_integrity_errors => Boolean] if set to true, integrity errors will result in caching failing silently
    # [:ignore_processing_errors => Boolean] if set to true, processing errors will result in caching failing silently
    #
    # === Examples
    #
    # Mounting uploaders on different columns.
    #
    #     class Song
    #       mount_uploaders :lyrics, LyricsUploader
    #       mount_uploaders :alternative_lyrics, LyricsUploader
    #       mount_uploaders :files, SongUploader
    #     end
    #
    # This will add an anonymous uploader with only the default settings:
    #
    #     class Data
    #       mount_uploaders :csv_files
    #     end
    #
    # this will add an anonymous uploader overriding the store_dir:
    #
    #     class Product
    #       mount_uploaders :blueprints do
    #         def store_dir
    #           'blueprints'
    #         end
    #       end
    #     end
    #
    def mount_uploaders(column, uploader=nil, options={}, &block)
      mount_base(column, uploader, options, &block)

      mod = Module.new
      include mod
      mod.class_eval <<-RUBY, __FILE__, __LINE__+1

        def #{column}
          _mounter(:#{column}).uploaders
        end

        def #{column}=(new_files)
          _mounter(:#{column}).cache(new_files)
        end

        def #{column}_urls(*args)
          _mounter(:#{column}).urls(*args)
        end

        def #{column}_cache
          names = _mounter(:#{column}).cache_names
          names.to_json if names.present?
        end

        def #{column}_cache=(cache_name)
          _mounter(:#{column}).cache_names = JSON.parse(cache_name) if cache_name.present?
        end

        def remote_#{column}_urls
          _mounter(:#{column}).remote_urls
        end

        def remote_#{column}_urls=(urls)
          _mounter(:#{column}).remote_urls = urls
        end

        def remote_#{column}_request_headers=(headers)
          _mounter(:#{column}).remote_request_headers = headers
        end

        def write_#{column}_identifier
          return if frozen?
          mounter = _mounter(:#{column})

          mounter.clear! if mounter.remove?
          write_uploader(mounter.serialization_column, mounter.identifiers.presence)
        end

        def #{column}_identifiers
          _mounter(:#{column}).read_identifiers
        end

        def store_previous_changes_for_#{column}
          attribute_changes = ::ActiveRecord.version.to_s.to_f >= 5.1 ? saved_changes : changes
          @_previous_changes_for_#{column} = attribute_changes[_mounter(:#{column}).serialization_column]
        end

        def remove_previously_stored_#{column}
          _mounter(:#{column}).remove_previous(*@_previous_changes_for_#{column})
        end
      RUBY
    end

    private

    def mount_base(column, uploader=nil, options={}, &block)
      include CarrierWave::Mount::Extension

      uploader = build_uploader(uploader, &block)
      uploaders[column.to_sym] = uploader
      uploader_options[column.to_sym] = options

      # Make sure to write over accessors directly defined on the class.
      # Simply super to the included module below.
      class_eval <<-RUBY, __FILE__, __LINE__+1
        def #{column}; super; end
        def #{column}=(new_file); super; end
      RUBY

      mod = Module.new
      include mod
      mod.class_eval <<-RUBY, __FILE__, __LINE__+1

        def #{column}?
          _mounter(:#{column}).present?
        end

        def remove_#{column}
          _mounter(:#{column}).remove
        end

        def remove_#{column}!
          _mounter(:#{column}).remove!
        end

        def remove_#{column}=(value)
          _mounter(:#{column}).remove = value
        end

        def remove_#{column}?
          _mounter(:#{column}).remove?
        end

        def store_#{column}!
          _mounter(:#{column}).store!
        end

        def #{column}_integrity_errors
          _mounter(:#{column}).integrity_errors
        end

        def #{column}_processing_errors
          _mounter(:#{column}).processing_errors
        end

        def #{column}_download_errors
          _mounter(:#{column}).download_errors
        end

        def mark_remove_#{column}_false
          _mounter(:#{column}).remove = false
        end
      RUBY
    end

    def build_uploader(uploader, &block)
      return uploader if uploader && !block_given?

      uploader = Class.new(uploader || CarrierWave::Uploader::Base)
      const_set("Uploader#{uploader.object_id}".tr('-', '_'), uploader)

      if block_given?
        uploader.class_eval(&block)
        uploader.recursively_apply_block_to_versions(&block)
      end

      uploader
    end

    module Extension

      ##
      # overwrite this to read from a serialized attribute
      #
      def read_uploader(column); end

      ##
      # overwrite this to write to a serialized attribute
      #
      def write_uploader(column, identifier); end

    private

      def _mounter(column)
        # We cannot memoize in frozen objects :(
        return Mounter.new(self, column) if frozen?
        @_mounters ||= {}
        @_mounters[column] ||= Mounter.new(self, column)
      end

    end # Extension

  end # Mount
end # CarrierWave

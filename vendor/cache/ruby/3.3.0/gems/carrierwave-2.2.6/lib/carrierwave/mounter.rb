module CarrierWave

  # this is an internal class, used by CarrierWave::Mount so that
  # we don't pollute the model with a lot of methods.
  class Mounter #:nodoc:
    attr_reader :column, :record, :remote_urls, :integrity_errors,
      :processing_errors, :download_errors
    attr_accessor :remove, :remote_request_headers

    def initialize(record, column, options={})
      @record = record
      @column = column
      @options = record.class.uploader_options[column]
      @download_errors = []
      @processing_errors = []
      @integrity_errors = []
    end

    def uploader_class
      record.class.uploaders[column]
    end

    def blank_uploader
      uploader_class.new(record, column)
    end

    def identifiers
      uploaders.map(&:identifier)
    end

    def read_identifiers
      [record.read_uploader(serialization_column)].flatten.reject(&:blank?)
    end

    def uploaders
      @uploaders ||= read_identifiers.map do |identifier|
        uploader = blank_uploader
        uploader.retrieve_from_store!(identifier) if identifier.present?
        uploader
      end
    end

    def cache(new_files)
      return if !new_files.is_a?(Array) && new_files.blank?
      old_uploaders = uploaders
      @uploaders = new_files.map do |new_file|
        handle_error do
          if new_file.is_a?(String)
            if (uploader = old_uploaders.detect { |uploader| uploader.identifier == new_file })
              uploader.staged = true
              uploader
            else
              begin
                uploader = blank_uploader
                uploader.retrieve_from_cache!(new_file)
                uploader
              rescue CarrierWave::InvalidParameter
                nil
              end
            end
          else
            uploader = blank_uploader
            uploader.cache!(new_file)
            uploader
          end
        end
      end.compact
    end

    def cache_names
      uploaders.map(&:cache_name).compact
    end

    def cache_names=(cache_names)
      cache_names = cache_names.reject(&:blank?)
      return if cache_names.blank?
      clear_unstaged
      cache_names.each do |cache_name|
        begin
          uploader = blank_uploader
          uploader.retrieve_from_cache!(cache_name)
          @uploaders << uploader
        rescue CarrierWave::InvalidParameter
          # ignore
        end
      end
    end

    def remote_urls=(urls)
      return if urls.blank? || urls.all?(&:blank?)

      @remote_urls = urls

      clear_unstaged
      urls.zip(remote_request_headers || []).each do |url, header|
        handle_error do
          uploader = blank_uploader
          uploader.download!(url, header || {})
          @uploaders << uploader
        end
      end
    end

    def store!
      uploaders.reject(&:blank?).each(&:store!)
    end

    def urls(*args)
      uploaders.map { |u| u.url(*args) }
    end

    def blank?
      uploaders.none?(&:present?)
    end

    def remove?
      remove.present? && (remove == true || remove !~ /\A0|false$\z/)
    end

    def remove!
      uploaders.reject(&:blank?).each(&:remove!)
      @uploaders = []
    end

    def clear!
      @uploaders = []
    end

    def serialization_column
      option(:mount_on) || column
    end

    def remove_previous(before=nil, after=nil)
      after ||= []
      return unless before

      # both 'before' and 'after' can be string when 'mount_on' option is set
      before = before.reject(&:blank?).map do |value|
        if value.is_a?(String)
          uploader = blank_uploader
          uploader.retrieve_from_store!(value)
          uploader
        else
          value
        end
      end
      after_paths = after.reject(&:blank?).map do |value|
        if value.is_a?(String)
          uploader = blank_uploader
          uploader.retrieve_from_store!(value)
          uploader
        else
          value
        end.path
      end
      before.each do |uploader|
        uploader.remove! if uploader.remove_previously_stored_files_after_update && !after_paths.include?(uploader.path)
      end
    end

    attr_accessor :uploader_options

  private

    def option(name)
      self.uploader_options ||= {}
      self.uploader_options[name] ||= record.class.uploader_option(column, name)
    end

    def clear_unstaged
      @uploaders ||= []
      @uploaders.keep_if(&:staged)
    end

    def handle_error
      yield
    rescue CarrierWave::DownloadError => e
      @download_errors << e
      raise e unless option(:ignore_download_errors)
    rescue CarrierWave::ProcessingError => e
      @processing_errors << e
      raise e unless option(:ignore_processing_errors)
    rescue CarrierWave::IntegrityError => e
      @integrity_errors << e
      raise e unless option(:ignore_integrity_errors)
    end
  end # Mounter
end # CarrierWave

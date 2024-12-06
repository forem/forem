# Copyright Cloudinary
require 'cloudinary/carrier_wave/process'
require 'cloudinary/carrier_wave/error'
require 'cloudinary/carrier_wave/remote'
require 'cloudinary/carrier_wave/preloaded'
require 'cloudinary/carrier_wave/storage' if defined?(::CarrierWave) # HACK

module Cloudinary::CarrierWave

  def self.included(base)
    base.storage Cloudinary::CarrierWave::Storage
    base.cache_storage = :file if base.cache_storage.blank?
    base.extend ClassMethods
    base.class_attribute :metadata
    base.class_attribute :storage_type, instance_reader: false
    override_in_versions(base, :blank?, :full_public_id, :my_public_id, :all_versions_processors, :stored_version)
  end

  def is_main_uploader?
    self.class.version_names.blank?
  end

  def stored_version
    @stored_version
  end

  def retrieve_from_store!(identifier)
    # Workaround cloudinary-mongoid hack of setting column to _old_ before saving it.
    mongoid_blank = defined?(Mongoid::Extensions::Object) && self.is_a?(Mongoid::Extensions::Object) && identifier == "_old_"
    if identifier.blank? || mongoid_blank
      @file = @stored_version = @stored_public_id = nil
      self.original_filename = nil
    else
      @file = CloudinaryFile.new(identifier, self)
      @public_id = @stored_public_id = @file.public_id
      @stored_version = @file.version
      self.original_filename = sanitize(@file.filename)
    end
  end

  def url(*args)
    if args.first && !args.first.is_a?(Hash)
      super
    else
      options = args.extract_options!
      if self.blank?
        url = self.default_url
        return url if !url.blank?
        public_id = self.default_public_id
        return nil if public_id.nil?
      else
        public_id = self.my_public_id
        options[:version] ||= self.stored_version
      end
      options = self.transformation.merge(options) if self.version_name.present?

      Cloudinary::Utils.cloudinary_url(public_id, {:format=>self.format, :resource_type=>self.resource_type, :type=>self.storage_type}.merge(options))
    end
  end

  def full_public_id
    return nil if self.blank?
    return self.my_public_id if self.stored_version.blank?
    return "v#{self.stored_version}/#{self.my_public_id}"
  end

  def filename
    return nil if self.blank?
    return [self.full_public_id, self.format].reject(&:blank?).join(".")
  end

  # default public_id to use if no uploaded file. Override with public_id of an uploaded image if you want a default image.
  def default_public_id
    nil
  end

  # public_id to use for uploaded file. Can be overridden by caller. Random public_id will be used otherwise.
  def public_id
    nil
  end

  # If the user overrode public_id, that should be used, even if it's different from current public_id in the database.
  # Otherwise, try to use public_id from the database.
  # Otherwise, generate a new random public_id
  def my_public_id
    @public_id ||= self.public_id
    @public_id ||= @stored_public_id
    @public_id ||= Cloudinary::Utils.random_public_id
  end

  def rename(to_public_id = nil, overwrite=false)
    public_id_overwrite = self.public_id
    to_public_id ||= public_id_overwrite
    if public_id_overwrite && to_public_id != public_id_overwrite
      raise CloudinaryException, "The public_id method was overridden and returns #{public_id_overwrite} - can't rename to #{to_public_id}"
    elsif to_public_id.nil?
      raise CloudinaryException, "No to_public_id given"
    end

    from_public_id = @stored_public_id || self.my_public_id
    return if from_public_id == to_public_id

    @public_id = @stored_public_id = to_public_id
    if self.resource_type == 'raw'
      from_public_id = [from_public_id, self.format].join(".")
      to_public_id = [to_public_id, self.format].join(".")
    end
    Cloudinary::Uploader.rename(from_public_id, to_public_id, :type=>self.storage_type, :resource_type=>self.resource_type, :overwrite=>overwrite)
    storage.store_cloudinary_identifier(@stored_version, [@public_id, self.format].join("."))
  end

  def recreate_versions!
    # Do nothing
  end

  def cache_versions!(new_file=nil)
    # Do nothing
  end

  def process!(new_file=nil)
    # Do nothing
  end

  SANITIZE_REGEXP = CarrierWave::SanitizedFile.respond_to?(:sanitize_regexp) ? CarrierWave::SanitizedFile.sanitize_regexp : /[^a-zA-Z0-9\.\-\+_]/
  def sanitize(filename)
    return nil if filename.nil?
    filename.gsub(SANITIZE_REGEXP, '_')
  end

  # Should removed files be removed from Cloudinary as well. Can be overridden.
  def delete_remote?
    true
  end

  # Let Cloudinary download remote URLs directly
  def cloudinary_should_handle_remote?
    true
  end

  # Rename preloaded uploads if public_id was overridden
  def auto_rename_preloaded?
    true
  end

  # Use extended identifier format that includes resource type and storage type.
  def use_extended_identifier?
    true
  end

  class CloudinaryFile
    attr_reader :identifier, :public_id, :filename, :format, :version, :storage_type, :resource_type
    def initialize(identifier, uploader)
      @uploader = uploader
      @identifier = identifier

      if @identifier.match(%r(^(image|raw|video)/(upload|private|authenticated)(?:/v([0-9]+))?/(.*)))
        @resource_type = $1
        @storage_type = $2
        @version = $3.presence
        @filename = $4
      elsif @identifier.match(%r(^v([0-9]+)/(.*)))
        @version = $1
        @filename = $2
      else
        @filename = @identifier
        @version = nil
      end

      @storage_type ||= uploader.class.storage_type
      @resource_type ||= Cloudinary::Utils.resource_type_for_format(@filename)
      @public_id, @format = Cloudinary::PreloadedFile.split_format(@filename)
    end

    def storage_identifier
      identifier
    end

    def delete
      public_id = @resource_type == "raw" ? self.filename : self.public_id
      Cloudinary::Uploader.destroy(public_id, :type=>self.storage_type, :resource_type=>self.resource_type) if @uploader.delete_remote?
    end

    def exists?
      public_id = @resource_type == "raw" ? self.filename : self.public_id
      Cloudinary::Uploader.exists?(public_id, :version=>self.version, :type=>self.storage_type, :resource_type=>self.resource_type)
    end

    def read(options={})
      parameters={:type=>self.storage_type, :resource_type=>self.resource_type}.merge(options)
      Cloudinary::Downloader.download(self.identifier, parameters)
    end

  end

  # @deprecated
  def self.split_format(identifier)
    return Cloudinary::PreloadedFile.split_format(identifier)
  end

  def default_format
    "png"
  end

  def storage_type
    @file.respond_to?(:storage_type) ? @file.storage_type : self.class.storage_type
  end

  def resource_type
    @file.respond_to?(:resource_type) ? @file.resource_type : Cloudinary::Utils.resource_type_for_format(requested_format || original_filename || default_format)
  end

  # For the given methods - versions should call the main uploader method
  def self.override_in_versions(base, *methods)
    methods.each do
      |method|
      base.send :define_method, method do
        return super() if self.version_name.blank?
        uploader = self.model.send(self.mounted_as)
        uploader.send(method)
      end
    end
  end
end

class Cloudinary::CarrierWave::Storage < ::CarrierWave::Storage::Abstract

  def store!(file)
    return unless uploader.enable_processing

    if uploader.is_main_uploader?
      case file
      when Cloudinary::CarrierWave::PreloadedCloudinaryFile
        storage_type = uploader.class.storage_type || "upload"
        raise CloudinaryException, "Uploader configured for type #{storage_type} but resource of type #{file.type} given." if storage_type.to_s != file.type
        if uploader.public_id && uploader.auto_rename_preloaded?
          @stored_version = file.version
          uploader.rename(nil, true)
        else
          store_cloudinary_identifier(file.version, file.filename, file.resource_type, file.type)
        end
        return # Nothing to do
      when Cloudinary::CarrierWave::CloudinaryFile, Cloudinary::CarrierWave::StoredFile
        return # Nothing to do
      when Cloudinary::CarrierWave::RemoteFile
        data = file.uri.to_s
      else
        data = file.file
        data.rewind if !file.is_path? && data.respond_to?(:rewind)
      end

      # This is the toplevel, need to upload the actual file.
      params = uploader.transformation.dup
      params[:return_error] = true
      params[:format] = uploader.requested_format
      params[:public_id] = uploader.my_public_id
      uploader.versions.values.each(&:tags) # Validate no tags in versions
      params[:tags] = uploader.tags if uploader.tags
      eager_versions = uploader.versions.values.select(&:eager)
      params[:eager] = eager_versions.map{|version| [version.transformation, version.format]} if eager_versions.length > 0
      params[:type]=uploader.class.storage_type

      params[:resource_type] ||= :auto
      uploader.metadata = Cloudinary::Uploader.upload(data, params)
      if uploader.metadata["error"]
        raise Cloudinary::CarrierWave::UploadError.new(uploader.metadata["error"]["message"], uploader.metadata["error"]["http_code"])
      end

      if uploader.metadata["version"]
        filename = [uploader.metadata["public_id"], uploader.metadata["format"]].reject(&:blank?).join(".")
        store_cloudinary_identifier(uploader.metadata["version"], filename, uploader.metadata["resource_type"], uploader.metadata["type"])
      end
      # Will throw an exception on error
    else
      raise CloudinaryException, "nested versions are not allowed." if (uploader.class.version_names.length > 1)
      # Do nothing - versions are not handled locally.
    end
    nil
  end

  def identifier
    uploader.file.respond_to?(:storage_identifier) ? uploader.file.storage_identifier : super
  end

  # Updates the model mounter identifier with version information.
  #
  # Carrierwave uses hooks when integrating with ORMs so it's important to
  # update the identifier in a way that does not trigger hooks again or else
  # you'll get stuck in a loop.
  def store_cloudinary_identifier(version, filename, resource_type=nil, type=nil)
    name = "v#{version}/#{filename}"
    if uploader.use_extended_identifier?
      resource_type ||= uploader.resource_type || "image"
      type ||= uploader.storage_type || "upload"
      name = "#{resource_type}/#{type}/#{name}"
    end
    model_class = uploader.model.class
    column = uploader.model.send(:_mounter, uploader.mounted_as).send(:serialization_column)
    original_value = uploader.model.read_attribute(column)
    return if original_value == name

    if original_value.is_a?(Array)
      if index = original_value.index(identifier)
        original_value[index] = name
      end
      name = original_value
    end

    if defined?(ActiveRecord::Base) && uploader.model.is_a?(ActiveRecord::Base)
      uploader.model.update_column(column, name)
    elsif defined?(Mongoid::Document) && uploader.model.is_a?(Mongoid::Document)
      # Mongoid support
      if Mongoid::VERSION.split(".").first.to_i >= 4
        column = column.to_sym
        uploader.model.write_attribute(column, name)
        uploader.model.set(column => name)
      else
        uploader.model.set(column, name)
      end
    elsif defined?(Neo4j::VERSION) && Neo4j::VERSION.split(".").first.to_i >= 5
        uploader.model.write_attribute(column, name)
    elsif defined?(Sequel::Model) && uploader.model.is_a?(Sequel::Model)
      # Sequel support
      uploader.model.this.update(column => name)
    elsif model_class.respond_to?(:update_all) && uploader.model.respond_to?(:_id)
      model_class.where(:_id=>uploader.model._id).update_all(column=>name)
      uploader.model.send :write_attribute, column, name
    else
      raise CloudinaryException, "Only ActiveRecord, Mongoid and Sequel are supported at the moment!"
    end
  end
end

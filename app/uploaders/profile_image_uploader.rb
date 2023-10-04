class ProfileImageUploader < BaseUploader
  MAX_FILE_SIZE = 8.megabytes

  def filename
    "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  def size_range
    1..MAX_FILE_SIZE
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end
end

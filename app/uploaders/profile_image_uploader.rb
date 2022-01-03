class ProfileImageUploader < BaseUploader
  def filename
    "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  def size_range
    1..(2.megabytes)
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) || model.instance_variable_set(var, SecureRandom.uuid)
  end
end

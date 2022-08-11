# This "model" is not backed by the database. Its main purpose is to
# setup and provide methods to interact with Extensions.

Extension = Struct.new(:name, :description, :feature_flag_name, keyword_init: true) do
  def enabled?
    FeatureFlag.enabled?(feature_flag_name)
  end

  def enable
    FeatureFlag.enable(feature_flag_name)
  end

  def disable
    FeatureFlag.disable(feature_flag_name)
  end
end

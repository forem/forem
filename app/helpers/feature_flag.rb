module FeatureFlag
  extend self # rubocop:disable Style/ModuleFunction

  def strict_enabled?(feature_name, *args)
    Flipper.enabled?(feature_name, *args)
  end

  def exist?(feature_name)
    Flipper.exist?(feature_name)
  end

  def enabled?(feature_name, *args)
    !exist?(feature_name) || strict_enabled?(feature_name, *args)
  end
end

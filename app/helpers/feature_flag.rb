module FeatureFlag
  extend self # rubocop:disable Style/ModuleFunction

  def enabled?(feature_name, *args)
    Flipper.enabled?(feature_name, *args)
  end

  def exist?(feature_name)
    Flipper.exist?(feature_name)
  end
end

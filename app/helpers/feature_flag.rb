module FeatureFlag
  extend self # rubocop:disable Style/ModuleFunction

  def enabled?(feature_name, *args)
    Flipper[feature_name].enabled?(*args)
  end
end

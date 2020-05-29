module FeatureFlag
  class << self
    delegate :enabled?, :exist?, to: Flipper

    def accessible?(feature_name, *args)
      feature_name.blank? || !exist?(feature_name) || enabled?(feature_name, *args)
    end
  end
end

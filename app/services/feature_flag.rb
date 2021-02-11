module FeatureFlag
  class << self
    delegate :add, :disable, :enable, :enabled?, :exist?, :remove, to: Flipper

    def accessible?(feature_flag_name, *args)
      feature_flag_name.blank? || !exist?(feature_flag_name) || enabled?(feature_flag_name, *args)
    end
  end
end

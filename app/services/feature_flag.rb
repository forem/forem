module FeatureFlag
  class << self
    delegate :enable, :enabled?, :exist?, to: Flipper

    def accessible?(feature_flag_name, *args)
      feature_flag_name.blank? || !exist?(feature_flag_name) || enabled?(feature_flag_name, *args)
    end
  end
end

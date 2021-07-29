return unless Rails.env.test? && ENV["E2E"].present?

FeatureFlag.enable(:creator_onboarding)

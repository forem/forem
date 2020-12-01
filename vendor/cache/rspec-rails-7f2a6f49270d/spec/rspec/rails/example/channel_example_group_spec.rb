require "rspec/rails/feature_check"

module RSpec::Rails
  RSpec.describe ChannelExampleGroup do
    if RSpec::Rails::FeatureCheck.has_action_cable_testing?
      it_behaves_like "an rspec-rails example group mixin", :channel,
                      './spec/channels/', '.\\spec\\channels\\'
    end
  end
end

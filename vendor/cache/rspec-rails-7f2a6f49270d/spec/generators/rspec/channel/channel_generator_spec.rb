# Generators are not automatically loaded by Rails
require "generators/rspec/channel/channel_generator"
require 'support/generators'

RSpec.describe Rspec::Generators::ChannelGenerator, type: :generator, skip: !RSpec::Rails::FeatureCheck.has_action_cable_testing? do
  setup_default_destination

  describe 'the generated files' do
    before { run_generator %w[chat] }

    subject { file("spec/channels/chat_channel_spec.rb") }

    it { is_expected.to exist }
    it { is_expected.to contain(/require 'rails_helper'/) }
    it { is_expected.to contain(/describe ChatChannel, #{type_metatag(:channel)}/) }
  end
end

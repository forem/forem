# Generators are not automatically loaded by Rails
require 'generators/rspec/mailbox/mailbox_generator'
require 'support/generators'

RSpec.describe Rspec::Generators::MailboxGenerator, type: :generator, skip: !RSpec::Rails::FeatureCheck.has_action_mailbox? do
  setup_default_destination

  describe 'the generated files' do
    before { run_generator %w[forwards] }

    subject { file('spec/mailboxes/forwards_mailbox_spec.rb') }

    it { is_expected.to exist }
    it { is_expected.to contain(/require 'rails_helper'/) }
    it { is_expected.to contain(/describe ForwardsMailbox, #{type_metatag(:mailbox)}/) }
  end
end

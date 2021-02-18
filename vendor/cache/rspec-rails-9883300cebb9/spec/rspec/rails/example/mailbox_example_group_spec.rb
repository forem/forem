require "rspec/rails/feature_check"

class ApplicationMailbox
  class << self
    attr_accessor :received

    def receive(*)
      self.received += 1
    end
  end

  self.received = 0
end

module RSpec
  module Rails
    RSpec.describe MailboxExampleGroup, skip: !RSpec::Rails::FeatureCheck.has_action_mailbox? do
      it_behaves_like "an rspec-rails example group mixin", :mailbox,
                      './spec/mailboxes/', '.\\spec\\mailboxes\\'

      def group_for(klass)
        RSpec::Core::ExampleGroup.describe klass do
          include MailboxExampleGroup
        end
      end

      let(:group) { group_for(::ApplicationMailbox) }
      let(:example) { group.new }

      describe '#have_been_delivered' do
        it 'raises on undelivered mail' do
          expect {
            expect(double('IncomingEmail', delivered?: false)).to example.have_been_delivered
          }.to raise_error(/have been delivered/)
        end

        it 'does not raise otherwise' do
          expect(double('IncomingEmail', delivered?: true)).to example.have_been_delivered
        end
      end

      describe '#have_bounced' do
        it 'raises on unbounced mail' do
          expect {
            expect(double('IncomingEmail', bounced?: false)).to example.have_bounced
          }.to raise_error(/have bounced/)
        end

        it 'does not raise otherwise' do
          expect(double('IncomingEmail', bounced?: true)).to example.have_bounced
        end
      end

      describe '#have_failed' do
        it 'raises on unfailed mail' do
          expect {
            expect(double('IncomingEmail', failed?: false)).to example.have_failed
          }.to raise_error(/have failed/)
        end

        it 'does not raise otherwise' do
          expect(double('IncomingEmail', failed?: true)).to example.have_failed
        end
      end

      describe '#process' do
        before do
          allow(RSpec::Rails::MailboxExampleGroup).to receive(:create_inbound_email) do |attributes|
            mail = double('Mail::Message', attributes)
            double('InboundEmail', mail: mail)
          end
        end

        it 'sends mail to the mailbox' do
          expect {
            example.process(to: ['test@example.com'])
          }.to change(::ApplicationMailbox, :received).by(1)
        end
      end
    end
  end
end

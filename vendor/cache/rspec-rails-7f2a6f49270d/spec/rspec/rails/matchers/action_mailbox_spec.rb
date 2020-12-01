require "rspec/rails/feature_check"

class ApplicationMailbox
  class Router
    def match_to_mailbox(*)
      Inbox
    end
  end

  def self.router
    Router.new
  end
end

class Inbox < ApplicationMailbox; end
class Otherbox < ApplicationMailbox; end

RSpec.describe "ActionMailbox matchers", skip: !RSpec::Rails::FeatureCheck.has_action_mailbox? do
  describe "receive_inbound_email" do
    let(:to) { ['to@example.com'] }

    before do
      allow(RSpec::Rails::MailboxExampleGroup).to receive(:create_inbound_email) do |attributes|
        mail = double('Mail::Message', attributes)
        double('InboundEmail', mail: mail)
      end
    end

    it "passes when it receives inbound email" do
      expect(Inbox).to receive_inbound_email(to: to)
    end

    it "passes when negated when it doesn't receive inbound email" do
      expect(Otherbox).not_to receive_inbound_email(to: to)
    end

    it "fails when it doesn't receive inbound email" do
      expect {
        expect(Otherbox).to receive_inbound_email(to: to)
      }.to raise_error(/expected mail to to@example.com to route to Otherbox, but routed to Inbox/)
    end

    it "fails when negated when it receives inbound email" do
      expect {
        expect(Inbox).not_to receive_inbound_email(to: to)
      }.to raise_error(/expected mail to to@example.com not to route to Inbox/)
    end
  end
end

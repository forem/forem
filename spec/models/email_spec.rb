# spec/models/email_spec.rb
require "rails_helper"

RSpec.describe Email, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to(:audience_segment).optional }
    it { is_expected.to belong_to(:event).optional }
  end

  describe "Callbacks" do
    it "registers #deliver_to_users as an after_commit callback" do
      # Verify the callback is registered in the chain
      # Note: checking private internal Rails structure is brittle but confirms configuration
      callback_names = Email._commit_callbacks.select { |cb| cb.kind == :after }.map(&:filter)
      expect(callback_names).to include(:deliver_to_users)
    end
  end

  describe "#deliver_to_users" do
    let!(:user_with_notifications) { create(:user, :with_newsletters) }
    let!(:user_without_notifications) { create(:user, :without_newsletters) }

    before do
      allow(Emails::EnqueueCustomBatchSendWorker).to receive(:perform_async).and_return(true)
    end

    context "when type_of equals 'onboarding_drip'" do
      let(:email) { create(:email, type_of: "onboarding_drip") }

      it "does not enqueue any jobs to EnqueueCustomBatchSendWorker" do
        expect(Emails::EnqueueCustomBatchSendWorker).not_to receive(:perform_async)
        # Manually trigger since after_commit doesn't run in transactional tests
        email.deliver_to_users
      end
    end

    context "when status is not 'active'" do
      let(:email) { create(:email, status: "draft") }

      it "does not enqueue any jobs to EnqueueCustomBatchSendWorker" do
        expect(Emails::EnqueueCustomBatchSendWorker).not_to receive(:perform_async)
        email.deliver_to_users
      end
    end

    context "when status is changed from 'draft' to 'active'" do
      let(:email) { create(:email, status: "draft") }

      context "and max user ID is over 5000" do
        it "enqueues 24 jobs to EnqueueCustomBatchSendWorker" do
          allow(User).to receive(:maximum).with(:id).and_return(6000)

          email.update(status: "active")
          email.deliver_to_users

          expect(Emails::EnqueueCustomBatchSendWorker).to have_received(:perform_async).exactly(24).times

          # Example assertions for boundaries
          expect(Emails::EnqueueCustomBatchSendWorker).to have_received(:perform_async).with(email.id, 1, 250)
          expect(Emails::EnqueueCustomBatchSendWorker).to have_received(:perform_async).with(email.id, 251, 500)
          expect(Emails::EnqueueCustomBatchSendWorker).to have_received(:perform_async).with(email.id, 5751,
                                                                                             6000)
        end

        it "only enqueues once even if re-saved" do
          allow(User).to receive(:maximum).with(:id).and_return(6000)

          email.update(status: "active")
          email.deliver_to_users
          expect(Emails::EnqueueCustomBatchSendWorker).to have_received(:perform_async).exactly(24).times

          # Clear expectations
          RSpec::Mocks.space.proxy_for(Emails::EnqueueCustomBatchSendWorker).reset
          allow(Emails::EnqueueCustomBatchSendWorker).to receive(:perform_async)

          email.reload.save
          email.deliver_to_users
          expect(Emails::EnqueueCustomBatchSendWorker).not_to have_received(:perform_async)
        end
      end

      context "and max user ID is 5000 or less" do
        it "enqueues a single job to EnqueueCustomBatchSendWorker" do
          allow(User).to receive(:maximum).with(:id).and_return(5000)

          email.update(status: "active")
          email.deliver_to_users

          expect(Emails::EnqueueCustomBatchSendWorker).to have_received(:perform_async).once.with(email.id)
        end
      end
    end

    it "updates the email status to 'delivered'" do
      email = create(:email, status: "draft") # Start as draft
      email.update(status: "active") # Make it active/dirty
      email.deliver_to_users
      expect(email.reload.status).to eq("delivered")
    end

    context "when Customer.io cutover is active" do
      let(:email) { create(:email, status: "draft") }

      before do
        allow(ForemInstance).to receive(:customerio_email_cutover?).and_return(true)
      end

      it "does not enqueue any jobs to EnqueueCustomBatchSendWorker" do
        email.update(status: "active")
        email.deliver_to_users

        expect(Emails::EnqueueCustomBatchSendWorker).not_to have_received(:perform_async)
      end
    end

    context "when Customer.io cutover is not active" do
      let(:email) { create(:email, status: "draft") }

      before do
        allow(ForemInstance).to receive(:customerio_email_cutover?).and_return(false)
      end

      it "enqueues a job to EnqueueCustomBatchSendWorker as before" do
        allow(User).to receive(:maximum).with(:id).and_return(5000)

        email.update(status: "active")
        email.deliver_to_users

        expect(Emails::EnqueueCustomBatchSendWorker).to have_received(:perform_async).once.with(email.id)
      end
    end
  end

  describe "#deliver_to_test_emails" do
    let(:email) { create(:email, subject: "Test Subject", body: "Test Body", type_of: "newsletter") }

    before do
      allow(Emails::BatchCustomSendWorker).to receive(:perform_async).and_return(true)
    end

    context "when a list of addresses is provided" do
      let!(:user_1) { create(:user, email: "test1@example.com") }
      let!(:user_2) { create(:user, email: "test2@example.com") }

      it "enqueues a job with the matching users" do
        addresses_string = "test1@example.com, test2@example.com"
        expect(Emails::BatchCustomSendWorker).to receive(:perform_async).with(
          contain_exactly(user_1.id, user_2.id),
          "[TEST] #{email.subject}",
          email.body,
          email.type_of,
          email.id,
          email.default_from_name_based_on_type,
        )
        email.deliver_to_test_emails(addresses_string)
      end
    end

    context "when no addresses are passed in but test_email_addresses is set" do
      let!(:user_1) { create(:user, email: "tester@example.com") }

      it "falls back to using test_email_addresses and enqueues a job" do
        email.test_email_addresses = "tester@example.com"
        # NOTE: match_array isn't strictly necessary for a single-element array,
        # but using it here for consistency is fine.
        expect(Emails::BatchCustomSendWorker).to receive(:perform_async).with(
          contain_exactly(user_1.id),
          "[TEST] #{email.subject}",
          email.body,
          email.type_of,
          email.id,
          email.default_from_name_based_on_type,
        )
        email.deliver_to_test_emails(nil)
      end
    end

    context "when the provided addresses do not match any user" do
      it "does not enqueue any jobs" do
        addresses_string = "nonexistent@example.com"
        expect(Emails::BatchCustomSendWorker).not_to receive(:perform_async)
        email.deliver_to_test_emails(addresses_string)
      end
    end

    context "when the addresses are blank" do
      it "does not enqueue any jobs" do
        expect(Emails::BatchCustomSendWorker).not_to receive(:perform_async)
        email.deliver_to_test_emails("")
      end
    end

    context "when Customer.io cutover is active" do
      before do
        create(:user, email: "test1@example.com")
        allow(ForemInstance).to receive(:customerio_email_cutover?).and_return(true)
      end

      it "does not enqueue any jobs to BatchCustomSendWorker" do
        email.deliver_to_test_emails("test1@example.com")

        expect(Emails::BatchCustomSendWorker).not_to have_received(:perform_async)
      end
    end

    context "when Customer.io cutover is not active" do
      let!(:user_1) { create(:user, email: "test1@example.com") }

      before do
        allow(ForemInstance).to receive(:customerio_email_cutover?).and_return(false)
      end

      it "enqueues a job to BatchCustomSendWorker as before" do
        email.deliver_to_test_emails("test1@example.com")

        expect(Emails::BatchCustomSendWorker).to have_received(:perform_async).with(
          contain_exactly(user_1.id),
          "[TEST] #{email.subject}",
          email.body,
          email.type_of,
          email.id,
          email.default_from_name_based_on_type,
        )
      end
    end
  end

  describe "Validations" do
    subject(:email) { build(:email) }

    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:body) }

    describe "custom_footer_html validation" do
      it "allows safe email HTML" do
        email.custom_footer_html = '<p style="color: #666;">Custom footer content</p>'
        expect(email).to be_valid
      end

      it "rejects unsafe HTML containing script tags" do
        email.custom_footer_html = '<p>Bad</p><script>alert("xss")</script>'
        expect(email).not_to be_valid
        expect(email.errors[:custom_footer_html]).to be_present
      end

      it "rejects unsafe HTML with javascript event handlers" do
        email.custom_footer_html = '<a href="#" onclick="alert(1)">Click</a>'
        expect(email).not_to be_valid
        expect(email.errors[:custom_footer_html]).to be_present
      end

      it "allows blank or nil custom_footer_html" do
        email.custom_footer_html = nil
        expect(email).to be_valid

        email.custom_footer_html = ""
        expect(email).to be_valid
      end
    end
  end

  describe "#footer_html_to_render" do
    let(:email) { build(:email) }

    context "when override_footer_html is false" do
      before do
        email.override_footer_html = false
      end

      it "returns the app-wide footer from Settings::General when set" do
        allow(Settings::General).to receive(:custom_email_footer).and_return("<p>App-wide footer</p>")
        expect(email.footer_html_to_render).to eq("<p>App-wide footer</p>")
      end

      it "returns nil when app-wide footer is blank" do
        allow(Settings::General).to receive(:custom_email_footer).and_return("")
        expect(email.footer_html_to_render).to be_nil
      end
    end

    context "when override_footer_html is true" do
      before do
        email.override_footer_html = true
      end

      it "returns the custom footer HTML when present" do
        email.custom_footer_html = "<p>Overridden footer</p>"
        allow(Settings::General).to receive(:custom_email_footer).and_return("<p>App-wide footer</p>")
        expect(email.footer_html_to_render).to eq("<p>Overridden footer</p>")
      end

      it "returns nil (suppressing the footer) when custom footer HTML is blank" do
        email.custom_footer_html = ""
        allow(Settings::General).to receive(:custom_email_footer).and_return("<p>App-wide footer</p>")
        expect(email.footer_html_to_render).to be_nil
      end

      it "returns nil when custom footer HTML is nil" do
        email.custom_footer_html = nil
        allow(Settings::General).to receive(:custom_email_footer).and_return("<p>App-wide footer</p>")
        expect(email.footer_html_to_render).to be_nil
      end
    end
  end

  describe "Targeting validations" do
    let(:segment) { create(:audience_segment) }
    let(:user_query) { create(:user_query, created_by: create(:user)) }
    let(:event) { create(:event) }

    it "is valid with only an audience segment" do
      email = build(:email, status: "draft", audience_segment: segment)
      expect(email).to be_valid
    end

    it "is valid with only a user query" do
      email = build(:email, status: "draft", user_query: user_query)
      expect(email).to be_valid
    end

    it "is valid with only an event target" do
      email = build(:email, status: "draft", event: event)
      expect(email).to be_valid
    end

    it "is valid with no target (all users broadcast)" do
      email = build(:email, status: "draft", audience_segment: nil, user_query: nil, event: nil)
      expect(email).to be_valid
    end

    it "is invalid if both an audience segment and a user query are specified" do
      email = build(:email, status: "draft", audience_segment: segment, user_query: user_query)
      expect(email).not_to be_valid
      expect(email.errors[:base]).to include(
        "Please select only one recipient target (Audience Segment, User Query, or Event).",
      )
    end

    it "is invalid if both an audience segment and an event are specified" do
      email = build(:email, status: "draft", audience_segment: segment, event: event)
      expect(email).not_to be_valid
      expect(email.errors[:base]).to include(
        "Please select only one recipient target (Audience Segment, User Query, or Event).",
      )
    end

    it "prevents activating an email when the audience segment is empty" do
      empty_segment = create(:audience_segment)
      email = build(:email, status: "active", audience_segment: empty_segment)
      expect(email).not_to be_valid
      expect(email.errors[:audience_segment_id]).to include("selected segment has no users")
    end

    it "allows activating an email when the audience segment has users" do
      populated_segment = create(:audience_segment)
      populated_segment.segmented_users.create!(user: create(:user))
      email = build(:email, status: "active", audience_segment: populated_segment)
      expect(email).to be_valid
    end
  end

  describe "#target_type_label" do
    it "returns the segment name when audience segment is present" do
      segment = create(:audience_segment, name: "VIP Beta")
      email = build(:email, status: "draft", audience_segment: segment)
      expect(email.target_type_label).to eq("Audience Segment: VIP Beta")
    end

    it "returns the query name when user query is present" do
      query = create(:user_query, name: "Top Writers", created_by: create(:user))
      email = build(:email, status: "draft", user_query: query)
      expect(email.target_type_label).to eq("User Query: Top Writers")
    end

    it "returns the event title when event is present" do
      event = create(:event, title: "Forem Hackathon")
      email = build(:email, status: "draft", event: event)
      expect(email.target_type_label).to eq("Event: Forem Hackathon")
    end

    it "returns 'All Users (Broadcast)' when no target is set" do
      email = build(:email, status: "draft", audience_segment: nil, user_query: nil, event: nil)
      expect(email.target_type_label).to eq("All Users (Broadcast)")
    end
  end
end

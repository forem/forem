# spec/workers/emails/drip_email_worker_spec.rb
require "rails_helper"

RSpec.describe Emails::DripEmailWorker, type: :worker do
  let(:worker) { described_class.new }
  let(:mailer) { double }
  let(:message_delivery) { double }
  let(:custom_onboarding_id) { 42 }
  let(:stubbed_default_id) { 999 }

  before do
    allow(Subforem).to receive(:cached_default_id).and_return(stubbed_default_id)
    allow(CustomMailer).to receive(:with).and_return(mailer)
    allow(mailer).to receive(:custom_email).and_return(message_delivery)
    allow(message_delivery).to receive(:deliver_now)
    allow(FeatureFlag).to receive(:enabled?).with("onboarding_drip_emails").and_return(true)
  end

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    let!(:default_email_day_1) do
      create(
        :email,
        type_of:               "onboarding_drip",
        drip_day:              1,
        subject:               "Default Day 1",
        body:                  "Default Content",
        onboarding_subforem_id: nil
      )
    end
    let!(:custom_email_day_1) do
      create(
        :email,
        type_of:               "onboarding_drip",
        drip_day:              1,
        subject:               "Custom Day 1",
        body:                  "Custom Content",
        onboarding_subforem_id: custom_onboarding_id
      )
    end
    let!(:default_email_day_2) do
      create(
        :email,
        type_of:               "onboarding_drip",
        drip_day:              2,
        subject:               "Default Day 2",
        body:                  "Default Content 2",
        onboarding_subforem_id: nil
      )
    end

    before do
      # Users for drip_day 1
      @user_day_1_in_window = create(
        :user,
        registered_at:         ((1 * 24) + 0.5).hours.ago,
        onboarding_subforem_id: nil
      )
      @user_day_1_custom   = create(
        :user,
        registered_at:         ((1 * 24) + 0.5).hours.ago,
        onboarding_subforem_id: custom_onboarding_id
      )
      @user_day_1_stubbed  = create(
        :user,
        registered_at:         ((1 * 24) + 0.5).hours.ago,
        onboarding_subforem_id: stubbed_default_id
      )
      @user_day_1_out_of_window = create(
        :user,
        registered_at:         ((1 * 24) + 2).hours.ago,
        onboarding_subforem_id: nil
      )

      # Users for drip_day 2
      @user_day_2_in_window = create(
        :user,
        registered_at:         ((2 * 24) + 0.5).hours.ago,
        onboarding_subforem_id: nil
      )
      @user_day_2_out_of_window = create(
        :user,
        registered_at:         ((2 * 24) + 2).hours.ago,
        onboarding_subforem_id: nil
      )

      # Email settings
      [@user_day_1_in_window, @user_day_1_custom, @user_day_1_stubbed,
       @user_day_1_out_of_window, @user_day_2_in_window, @user_day_2_out_of_window].each do |u|
        u.notification_setting.update!(email_newsletter: true)
      end

      # User who received an email in the last 12 hours
      @user_recent_email = create(
        :user,
        registered_at:         ((1 * 24) + 0.5).hours.ago,
        onboarding_subforem_id: nil
      )
      create(:email_message, user: @user_recent_email, sent_at: 11.hours.ago)
    end

    it "sends the default template to users with nil onboarding_subforem_id" do
      worker.perform
      expect(CustomMailer).to have_received(:with).with(
        user:     @user_day_1_in_window,
        subject:  default_email_day_1.subject,
        content:  default_email_day_1.body,
        type_of:  default_email_day_1.type_of,
        email_id: default_email_day_1.id
      ).once
    end

    it "sends custom template to users with their own onboarding_subforem_id" do
      worker.perform
      expect(CustomMailer).to have_received(:with).with(
        user:     @user_day_1_custom,
        subject:  custom_email_day_1.subject,
        content:  custom_email_day_1.body,
        type_of:  custom_email_day_1.type_of,
        email_id: custom_email_day_1.id
      ).once
    end

    it "uses the stubbed default_id grouping when Subforem.cached_default_id is stubbed" do
      # stubbed_default_id users should receive the nil template (first in default group)
      worker.perform
      expect(CustomMailer).to have_received(:with).with(
        user:     @user_day_1_stubbed,
        subject:  default_email_day_1.subject,
        content:  default_email_day_1.body,
        type_of:  default_email_day_1.type_of,
        email_id: default_email_day_1.id
      ).once
    end

    it "does not send emails to users registered outside the drip window" do
      worker.perform
      expect(CustomMailer).not_to have_received(:with).with(
        user: @user_day_1_out_of_window,
        subject: default_email_day_1.subject,
        content: default_email_day_1.body,
        type_of: default_email_day_1.type_of,
        email_id: default_email_day_1.id
      )
      expect(CustomMailer).not_to have_received(:with).with(
        user: @user_day_2_out_of_window,
        subject: default_email_day_2.subject,
        content: default_email_day_2.body,
        type_of: default_email_day_2.type_of,
        email_id: default_email_day_2.id
      )
    end

    it "does not send emails to users unsubscribed or recently emailed" do
      # Unsubscribed
      unsub = create(:user, registered_at: ((1 * 24) + 0.5).hours.ago)
      unsub.notification_setting.update!(email_newsletter: false)
      # Recently emailed follows existing setup

      worker.perform
      expect(CustomMailer).not_to have_received(:with).with(hash_including(user: unsub))
      expect(CustomMailer).not_to have_received(:with).with(hash_including(user: @user_recent_email))
    end
  end
end

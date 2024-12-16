require 'rails_helper'

RSpec.describe Emails::DripEmailWorker, type: :worker do
  let(:worker) { described_class.new }
  let(:mailer) { double }
  let(:message_delivery) { double }

  before do
    allow(CustomMailer).to receive(:with).and_return(mailer)
    allow(mailer).to receive(:custom_email).and_return(message_delivery)
    allow(message_delivery).to receive(:deliver_now)
    allow(FeatureFlag).to receive(:enabled?).with('onboarding_drip_emails').and_return(true)
  end

  include_examples '#enqueues_on_correct_queue', 'medium_priority'

  describe '#perform' do
    let!(:email_template_day_1) do
      create(:email, type_of: 'onboarding_drip', drip_day: 1, subject: 'Welcome Day 1', body: 'Hello Day 1')
    end
    let!(:email_template_day_2) do
      create(:email, type_of: 'onboarding_drip', drip_day: 2, subject: 'Welcome Day 2', body: 'Hello Day 2')
    end
    # No email template for drip_day 3 to test missing template scenario

    before do
      # Users for drip_day 1
      @user_day_1_in_window = create(:user, registered_at: ((1 * 24) + 0.5).hours.ago)
      @user_day_1_out_of_window = create(:user, registered_at: ((1 * 24) + 2).hours.ago)


      # Users for drip_day 2
      @user_day_2_in_window = create(:user, registered_at: ((2 * 24) + 0.5).hours.ago)
      @user_day_2_out_of_window = create(:user, registered_at: ((2 * 24) + 2).hours.ago)

      # Email settings
      @user_day_1_in_window.notification_setting.email_newsletter = true
      @user_day_1_in_window.notification_setting.save
      @user_day_1_out_of_window.notification_setting.email_newsletter = true
      @user_day_1_out_of_window.notification_setting.save
      @user_day_2_in_window.notification_setting.email_newsletter = true
      @user_day_2_in_window.notification_setting.save
      @user_day_2_out_of_window.notification_setting.email_newsletter = true
      @user_day_2_out_of_window.notification_setting.save      

      # User who received an email in the last 12 hours
      @user_recent_email = create(:user, registered_at: ((1 * 24) + 0.5).hours.ago)
      create(:email_message, user: @user_recent_email, sent_at: 11.hours.ago)

    end

    it 'sends emails to users for drip days with email templates' do
      worker.perform

      expect(CustomMailer).to have_received(:with).with(
        user: @user_day_1_in_window,
        subject: email_template_day_1.subject,
        content: email_template_day_1.body,
        type_of: email_template_day_1.type_of,
        email_id: email_template_day_1.id
      ).once
      expect(CustomMailer).to have_received(:with).with(
        user: @user_day_2_in_window,
        subject: email_template_day_2.subject,
        content: email_template_day_2.body,
        type_of: email_template_day_2.type_of,
        email_id: email_template_day_2.id
      ).once

      expect(mailer).to have_received(:custom_email).twice
      expect(message_delivery).to have_received(:deliver_now).twice
    end

    it 'does not send emails to users registered outside the time window' do
      worker.perform

      expect(CustomMailer).not_to have_received(:with).with(
        user: @user_day_1_out_of_window,
        subject: email_template_day_1.subject,
        content: email_template_day_1.body,
        type_of: email_template_day_1.type_of,
        email_id: email_template_day_1.id
      )
      expect(CustomMailer).not_to have_received(:with).with(
        user: @user_day_2_out_of_window,
        subject: email_template_day_2.subject,
        content: email_template_day_2.body,
        type_of: email_template_day_2.type_of,
        email_id: email_template_day_2.id
      )
    end

    it 'does not send emails for drip days without email templates' do
      worker.perform

      # Assuming drip_day 3 has no email template
      expect(CustomMailer).not_to have_received(:with).with(
        hash_including(subject: 'Welcome Day 3')
      )
    end

    it 'does not send emails to users who received an email in the last 12 hours' do
      worker.perform

      expect(CustomMailer).not_to have_received(:with).with(
        user: @user_recent_email,
        subject: email_template_day_1.subject,
        content: email_template_day_1.body,
        type_of: email_template_day_1.type_of,
        email_id: email_template_day_1.id
      )
    end

    it "does not send email to user who is unsubscribed to user.notification_setting.email_newsletter" do
      user = create(:user, registered_at: ((1 * 24) + 0.5).hours.ago)
      user.notification_setting.email_newsletter = false
      user.notification_setting.save

      worker.perform

      expect(CustomMailer).not_to have_received(:with).with(
        user: user,
        subject: email_template_day_1.subject,
        content: email_template_day_1.body,
        type_of: email_template_day_1.type_of,
        email_id: email_template_day_1.id
      )
    end

    it 'sends emails to users who have not received an email in the last 12 hours' do
      # User who received an email more than 12 hours ago
      user_old_email = create(:user, registered_at: ((1 * 24) + 0.5).hours.ago)
      user_old_email.notification_setting.email_newsletter = true
      user_old_email.notification_setting.save
      create(:email_message, user: user_old_email, sent_at: 13.hours.ago)

      worker.perform

      expect(CustomMailer).to have_received(:with).with(
        user: user_old_email,
        subject: email_template_day_1.subject,
        content: email_template_day_1.body,
        type_of: email_template_day_1.type_of,
        email_id: email_template_day_1.id
      )
      expect(mailer).to have_received(:custom_email).exactly(3).times
      expect(message_delivery).to have_received(:deliver_now).exactly(3).times
    end

    it 'processes all drip days up to the maximum drip day' do
      worker.perform

      # Ensure emails are sent for drip days 1 and 2
      expect(CustomMailer).to have_received(:with).with(
        user: @user_day_1_in_window,
        subject: email_template_day_1.subject,
        content: email_template_day_1.body,
        type_of: email_template_day_1.type_of,
        email_id: email_template_day_1.id
      ).once
      expect(CustomMailer).to have_received(:with).with(
        user: @user_day_2_in_window,
        subject: email_template_day_2.subject,
        content: email_template_day_2.body,
        type_of: email_template_day_2.type_of,
        email_id: email_template_day_2.id
      ).once

      # Ensure no emails are sent for drip day 3 (no email template)
      expect(CustomMailer).not_to have_received(:with).with(
        hash_including(subject: 'Welcome Day 3')
      )

      # Total number of emails sent should match the number of users in the window
      expect(mailer).to have_received(:custom_email).exactly(2).times
      expect(message_delivery).to have_received(:deliver_now).exactly(2).times
    end
  end
end

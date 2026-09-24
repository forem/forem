require "rails_helper"

RSpec.describe Emails::SurveyDailyEmailWorker, type: :worker do
  let!(:active_survey) { create(:survey, active: true, daily_email_distributions: 2) }
  let!(:inactive_survey) { create(:survey, active: false, daily_email_distributions: 5) }
  let!(:no_email_survey) { create(:survey, active: true, daily_email_distributions: 0) }

  # Eligible users
  let!(:eligible_user1) { create(:user, last_presence_at: 1.month.ago) }
  let!(:eligible_user2) { create(:user, last_presence_at: 2.months.ago) }
  let!(:eligible_user3) { create(:user, last_presence_at: 1.day.ago) }

  # Ineligible users
  let!(:suspended_user) { create(:user, last_presence_at: 1.month.ago).tap { |u| u.add_role(:suspended) } }
  let!(:spam_user) { create(:user, last_presence_at: 1.month.ago).tap { |u| u.add_role(:spam) } }
  let!(:no_newsletter_user) do
    create(:user, last_presence_at: 1.month.ago).tap do |u|
      u.notification_setting.update(email_newsletter: false)
    end
  end
  let!(:no_email_user) { create(:user, email: nil, last_presence_at: 1.month.ago) }
  let!(:stale_user) { create(:user, last_presence_at: 4.months.ago) }

  before do
    # ensure emails are present for eligible users as factory might not guarantee valid email sometimes depending on traits
    [eligible_user1, eligible_user2, eligible_user3].each do |user|
      user.update!(email: "user_#{user.id}@example.com")
      user.notification_setting.update!(email_newsletter: true)
    end

    # Stub hourly_send_limit to return the full daily distributions for legacy daily tests
    allow_any_instance_of(Emails::SurveyDailyEmailWorker).to receive(:hourly_send_limit) do |_worker, survey|
      survey.daily_email_distributions
    end
  end

  it "only processes active surveys with daily_email_distributions > 0" do
    expect(active_survey.daily_email_distributions).to eq(2)
    
    mailer_double = double(pulse_survey: double(deliver_later: true))
    expect(SurveyMailer).to receive(:with).exactly(2).times.and_return(mailer_double)
    
    subject.perform
  end

  context "when allow_resubmission is false" do
    let!(:active_survey) { create(:survey, active: true, daily_email_distributions: 2, allow_resubmission: false) }
    let!(:completed_user) { create(:user, last_presence_at: 1.month.ago, email: "comp@example.com").tap { |u| u.notification_setting.update!(email_newsletter: true) } }
    let!(:started_user) { create(:user, last_presence_at: 1.month.ago, email: "start@example.com").tap { |u| u.notification_setting.update!(email_newsletter: true) } }
    
    before do
      create(:survey_completion, survey: active_survey, user: completed_user)
      poll = create(:poll, survey: active_survey)
      poll_option = create(:poll_option, poll: poll)
      create(:poll_vote, poll: poll, poll_option: poll_option, user: started_user)
    end

    it "samples the exact number of eligible users defined in daily_email_distributions and ignores users who started/completed it" do
      mailer_double = double(pulse_survey: double(deliver_later: true))
      expect(SurveyMailer).to receive(:with).with(hash_including(survey: active_survey)).exactly(2).times.and_return(mailer_double)
      expect(SurveyMailer).not_to receive(:with).with(hash_including(user: completed_user))
      expect(SurveyMailer).not_to receive(:with).with(hash_including(user: started_user))
      
      subject.perform
    end
  end

  context "when allow_resubmission is true" do
    let!(:active_survey) { create(:survey, active: true, daily_email_distributions: 1, allow_resubmission: true) }
    let!(:completed_user) { create(:user, last_presence_at: 1.month.ago, email: "comp2@example.com").tap { |u| u.notification_setting.update!(email_newsletter: true) } }

    before do
      create(:survey_completion, survey: active_survey, user: completed_user)
      # Temporarily restrict eligible users in this test just to this one
      User.where.not(id: completed_user.id).update_all(last_presence_at: 4.months.ago) 
    end

    it "includes users who have already completed the survey" do
      mailer_double = double(pulse_survey: double(deliver_later: true))
      expect(SurveyMailer).to receive(:with).with(hash_including(user: completed_user, survey: active_survey)).once.and_return(mailer_double)
      
      subject.perform
    end
  end

  describe "target-based and hourly sending features" do
    let(:mailer_double) { double(pulse_survey: double(deliver_later: true)) }

    before do
      # Ensure there are no other active surveys that would send emails and interfere with our tests
      Survey.update_all(active: false)

      # Use actual implementation of hourly_send_limit for target tests
      allow_any_instance_of(Emails::SurveyDailyEmailWorker).to receive(:hourly_send_limit).and_call_original
    end

    context "when target response count is reached" do
      let!(:survey) { create(:survey, active: true, target_response_count: 3, target_completion_date: 5.days.from_now, daily_email_distributions: 10) }

      before do
        create_list(:survey_completion, 3, survey: survey)
      end

      it "deactivates the survey and does not send any emails" do
        expect(SurveyMailer).not_to receive(:with)
        subject.perform
        expect(survey.reload.active).to be false
      end
    end

    context "when target completion date has passed" do
      let!(:survey) { create(:survey, active: true, target_response_count: 10, target_completion_date: 2.days.from_now, daily_email_distributions: 10) }

      before do
        # bypass validation to set it in the past
        survey.update_columns(target_completion_date: 1.day.ago)
      end

      it "deactivates the survey and does not send any emails" do
        expect(SurveyMailer).not_to receive(:with)
        subject.perform
        expect(survey.reload.active).to be false
      end
    end

    context "when sending hourly portion of daily rate" do
      let!(:survey) { create(:survey, active: true, daily_email_distributions: 24, allow_resubmission: true) }

      it "sends exactly 1 email at hour 0" do
        allow(Time).to receive(:current).and_return(Time.zone.now.beginning_of_day) # hour 0
        expect(SurveyMailer).to receive(:with).once.and_return(mailer_double)
        subject.perform
      end

      it "sends exactly 1 email at hour 12" do
        allow(Time).to receive(:current).and_return(Time.zone.now.beginning_of_day + 12.hours) # hour 12
        expect(SurveyMailer).to receive(:with).once.and_return(mailer_double)
        subject.perform
      end

      it "does not send any emails if hourly count is 0" do
        # 10 daily distributions, hour 0 -> (1 * 10) / 24 - 0 = 0
        survey.update!(daily_email_distributions: 10)
        allow(Time).to receive(:current).and_return(Time.zone.now.beginning_of_day) # hour 0
        expect(SurveyMailer).not_to receive(:with)
        subject.perform
      end
    end

    context "when adjusting the send rate" do
      # 100 completions needed. 5 days remaining. 25 hours since started sending.
      # 10 completions done so far. 1000 emails sent.
      # conversion rate = 10 / 1000 = 1%.
      # remaining completions needed = 90.
      # required daily completion rate = 90 / 5 = 18.
      # new daily send rate = 18 / 0.01 = 1800.
      let!(:survey) do
        s = create(:survey, active: true, target_response_count: 100, daily_email_distributions: 4000)
        s.update_columns(
          target_completion_date: 5.days.from_now,
          sending_started_at: 25.hours.ago,
          emails_sent_count: 1000
        )
        s
      end

      before do
        create_list(:survey_completion, 10, survey: survey)
      end

      it "updates daily_email_distributions based on actual conversion rate" do
        # We also mock the time to prevent time drifts in the calculations
        now = Time.zone.now
        allow(Time).to receive(:current).and_return(now)
        
        # Stub the hourly sending so it doesn't try to send 1800 / 24 = 75 emails
        # which would require 75 eligible users and output mock clutter
        allow(subject).to receive(:send_hourly_emails)

        subject.perform
        expect(survey.reload.daily_email_distributions).to eq(1800)
      end
    end
  end
end

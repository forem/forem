require "rails_helper"

RSpec.describe Emails::SurveyDailyEmailWorker, type: :worker do
  let(:worker) { described_class.new }
  let(:mail_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }
  let(:mailer_double) { instance_double(SurveyMailer, pulse_survey: mail_delivery) }

  def create_eligible_user(email: generate(:email), last_presence_at: 1.month.ago)
    create(:user, email: email, last_presence_at: last_presence_at).tap do |user|
      user.notification_setting.update!(email_newsletter: true)
    end
  end

  before do
    allow(SurveyMailer).to receive(:with).and_return(mailer_double)
    allow(worker).to receive(:hourly_send_limit, &:daily_email_distributions)
  end

  it "only processes active surveys with daily_email_distributions > 0", :aggregate_failures do
    active_survey = create(:survey, active: true, daily_email_distributions: 2)
    create(:survey, active: false, daily_email_distributions: 5)
    create(:survey, active: true, daily_email_distributions: 0)

    eligible_user1 = create_eligible_user(last_presence_at: 1.month.ago)
    eligible_user2 = create_eligible_user(last_presence_at: 1.day.ago)

    create(:user, last_presence_at: 1.month.ago).tap { |u| u.add_role(:suspended) }
    create(:user, last_presence_at: 1.month.ago).tap { |u| u.add_role(:spam) }
    create(:user, last_presence_at: 1.month.ago).tap { |u| u.notification_setting.update(email_newsletter: false) }
    create(:user, email: nil, last_presence_at: 1.month.ago)
    create(:user, last_presence_at: 4.months.ago)

    worker.perform

    expect(SurveyMailer).to have_received(:with).twice
    expect(SurveyMailer).to have_received(:with).with(hash_including(user: eligible_user1, survey: active_survey)).once
    expect(SurveyMailer).to have_received(:with).with(hash_including(user: eligible_user2, survey: active_survey)).once
  end

  context "when allow_resubmission is false" do
    let!(:active_survey) { create(:survey, active: true, daily_email_distributions: 2, allow_resubmission: false) }
    let!(:eligible_user1) { create_eligible_user(last_presence_at: 1.month.ago) }
    let!(:eligible_user2) { create_eligible_user(last_presence_at: 2.months.ago) }
    let!(:completed_user) { create_eligible_user(email: "comp@example.com") }
    let!(:started_user) { create_eligible_user(email: "start@example.com") }

    before do
      create(:survey_completion, survey: active_survey, user: completed_user)
      poll = create(:poll, survey: active_survey, article: nil)
      create(:poll_vote, poll: poll, poll_option: poll.poll_options.first, user: started_user)
    end

    it "samples eligible users up to daily_email_distributions and ignores users who started/completed it",
       :aggregate_failures do
      worker.perform

      expect(SurveyMailer).to have_received(:with).with(hash_including(survey: active_survey)).twice
      expect(SurveyMailer).to have_received(:with).with(hash_including(user: eligible_user1, survey: active_survey))
      expect(SurveyMailer).to have_received(:with).with(hash_including(user: eligible_user2, survey: active_survey))
      expect(SurveyMailer).not_to have_received(:with).with(hash_including(user: completed_user))
      expect(SurveyMailer).not_to have_received(:with).with(hash_including(user: started_user))
    end
  end

  context "when allow_resubmission is true" do
    let!(:active_survey) { create(:survey, active: true, daily_email_distributions: 1, allow_resubmission: true) }
    let!(:completed_user) { create_eligible_user(email: "comp2@example.com") }

    before do
      create(:survey_completion, survey: active_survey, user: completed_user)
    end

    it "includes users who have already completed the survey" do
      worker.perform

      expect(SurveyMailer).to have_received(:with).with(hash_including(user: completed_user, survey: active_survey))
    end
  end

  describe "target-based and hourly sending features" do
    before do
      allow(worker).to receive(:hourly_send_limit).and_call_original
    end

    context "when target response count is reached" do
      let!(:survey) do
        create(:survey, active: true, target_response_count: 1, target_completion_date: 5.days.from_now,
                        daily_email_distributions: 24)
      end

      before do
        create(:survey_completion, survey: survey)
      end

      it "deactivates the survey and does not send any emails", :aggregate_failures do
        create_eligible_user
        worker.perform

        expect(SurveyMailer).not_to have_received(:with)
        expect(survey.reload.active).to be false
      end
    end

    context "when target completion date has passed" do
      let!(:survey) do
        create(:survey, active: true, target_response_count: 10, target_completion_date: 2.days.from_now,
                        daily_email_distributions: 24)
      end

      before do
        # bypass validation to set it in the past
        survey.update_columns(target_completion_date: 1.day.ago)
      end

      it "deactivates the survey and does not send any emails", :aggregate_failures do
        create_eligible_user
        worker.perform

        expect(SurveyMailer).not_to have_received(:with)
        expect(survey.reload.active).to be false
      end
    end

    context "when sending hourly portion of daily rate" do
      let!(:survey) { create(:survey, active: true, daily_email_distributions: 24, allow_resubmission: true) }

      it "sends exactly 1 email at hour 0" do
        2.times { create_eligible_user }
        allow(Time).to receive(:current).and_return(Time.zone.now.beginning_of_day) # hour 0
        worker.perform
        expect(SurveyMailer).to have_received(:with).once
      end

      it "sends exactly 1 email at hour 12" do
        create_eligible_user
        allow(Time).to receive(:current).and_return(Time.zone.now.beginning_of_day + 12.hours) # hour 12
        worker.perform
        expect(SurveyMailer).to have_received(:with).once
      end

      it "does not send any emails if hourly count is 0" do
        create_eligible_user
        # 10 daily distributions, hour 0 -> (1 * 10) / 24 - 0 = 0
        survey.update!(daily_email_distributions: 10)
        allow(Time).to receive(:current).and_return(Time.zone.now.beginning_of_day) # hour 0
        worker.perform
        expect(SurveyMailer).not_to have_received(:with)
      end
    end

    context "when adjusting the send rate" do
      # 10 completions needed. 5 days (120 hours) remaining. 25 hours since started sending.
      # 1 completion done so far. 100 emails sent.
      # conversion rate = 1 / 100 = 1%.
      # remaining completions needed = 9.
      # required daily completion rate = 9 / 5 = 1.8.
      # new daily send rate = 1.8 / 0.01 = 180.
      let(:now) { Time.zone.now.beginning_of_day }
      let!(:survey) do
        s = create(:survey, active: true, target_response_count: 10, daily_email_distributions: 4000)
        s.update_columns(
          target_completion_date: now + 120.hours,
          sending_started_at: now - 25.hours,
          emails_sent_count: 100,
        )
        s
      end

      before do
        create(:survey_completion, survey: survey)
      end

      it "updates daily_email_distributions based on actual conversion rate" do
        # Mock the time to prevent time drifts and DST calendar-day shifts in the calculations
        allow(Time).to receive(:current).and_return(now)

        worker.perform
        expect(survey.reload.daily_email_distributions).to eq(180)
      end
    end
  end
end

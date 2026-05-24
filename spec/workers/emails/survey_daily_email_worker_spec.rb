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
end

require "rails_helper"

RSpec.describe SurveyMailer, type: :mailer do
  describe "pulse_survey" do
    let(:user) { create(:user) }
    let(:survey) { create(:survey, title: "Standard Survey", extra_email_context_paragraph: "This is a super important survey.") }
    let(:mail) { SurveyMailer.with(user: user, survey: survey).pulse_survey }
    let(:community_name) { Settings::Community.community_name }

    it "renders the headers" do
      expect(mail.subject).to eq("You've been randomly selected for a #{community_name} Pulse Survey")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body with link to survey" do
      expect(mail.body.encoded).to include(user.name)
      expect(mail.body.encoded).to include(survey.slug)
      expect(mail.body.encoded).to include("Take the #{community_name} Pulse Survey")
      expect(mail.body.encoded).to include("This is a super important survey.")
    end
  end
end

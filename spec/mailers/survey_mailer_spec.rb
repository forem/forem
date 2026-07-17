require "rails_helper"

RSpec.describe SurveyMailer, type: :mailer do
  describe "pulse_survey" do
    let(:user) { create(:user) }
    let(:survey) { create(:survey, title: "Standard Survey", extra_email_context_paragraph: "This is a super important survey.") }
    let(:mail) { SurveyMailer.with(user: user, survey: survey).pulse_survey }
    let(:community_name) { Settings::Community.community_name }

    context "when survey is community_pulse (default)" do
      it "renders the headers" do
        expect(mail.subject).to eq("You've been randomly selected for a #{community_name} Pulse Survey")
        expect(mail.to).to eq([user.email])
      end

      it "renders the body with link to survey" do
        expect(mail.body.encoded).to include(user.name)
        expect(mail.body.encoded).to include(survey.slug)
        expect(mail.body.encoded).to include("Take the #{community_name} Pulse Survey")
        expect(mail.body.encoded).to include("This is a super important survey.")
        expect(mail.body.encoded).to include("randomly selected to participate in a #{community_name} Pulse Survey.")
      end

      it "uses SMTP delivery when Customer.io is not configured" do
        expect(mail.message.delivery_method).not_to be_a(DeliveryMethods::CustomerIo)
      end
    end

    context "when survey is industry" do
      let(:survey) { create(:survey, title: "Industry Survey", type_of: :industry, extra_email_context_paragraph: "Industry details.") }

      it "renders the headers" do
        expect(mail.subject).to eq("You've been randomly selected for a very quick #{community_name} Industry Survey")
      end

      it "renders the body with link to survey" do
        expect(mail.body.encoded).to include("Take the #{community_name} Industry Survey")
        expect(mail.body.encoded).to include("Industry details.")
        expect(mail.body.encoded).to include("invite you to participate in a #{community_name} Industry Survey.")
      end
    end

    context "when survey is fun" do
      let(:survey) { create(:survey, title: "Fun Survey", type_of: :fun, extra_email_context_paragraph: "Fun details.") }

      it "renders the headers" do
        expect(mail.subject).to eq("A quick, fun survey from #{community_name}!")
      end

      it "renders the body with link to survey" do
        expect(mail.body.encoded).to include("Take this quick #{community_name} Survey")
        expect(mail.body.encoded).to include("Fun details.")
        expect(mail.body.encoded).to include("invite you to participate in a quick, fun survey from #{community_name}.")
      end
    end

    context "when routed through Customer.io with the default (pulse) survey" do
      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "routes through the Customer.io pulse survey template", :aggregate_failures do
        settings = mail.message.delivery_method.settings
        expected_subject = "You've been randomly selected for a #{community_name} Pulse Survey"

        expect(settings[:transactional_message_id]).to eq("dev_pulse_survey")
        expect(settings[:message_data]["survey_type"]).to eq("pulse")
        expect(settings[:message_data]["survey_url"]).to eq(survey_url(survey.slug))
        expect(settings[:message_data]["community_name"]).to eq(community_name)
        expect(settings[:message_data]["subject"]).to eq(expected_subject)
      end
    end

    context "when routed through Customer.io with an industry survey" do
      let(:survey) { create(:survey, title: "Industry Survey", type_of: :industry) }

      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "sends the industry survey type" do
        settings = mail.message.delivery_method.settings

        expect(settings[:message_data]["survey_type"]).to eq("industry")
      end
    end

    context "when routed through Customer.io with a fun survey" do
      let(:survey) { create(:survey, title: "Fun Survey", type_of: :fun) }

      before do
        allow(ApplicationConfig).to receive(:[]).and_call_original
        allow(ApplicationConfig).to receive(:[]).with("CUSTOMERIO_APP_KEY").and_return("app-key")
        FeatureFlag.enable(Deliverable::CUSTOMERIO_FLAG, FeatureFlag::Actor[user])
      end

      after { FeatureFlag.remove(Deliverable::CUSTOMERIO_FLAG) }

      it "sends the fun survey type" do
        settings = mail.message.delivery_method.settings

        expect(settings[:message_data]["survey_type"]).to eq("fun")
      end
    end
  end
end

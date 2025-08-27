require "rails_helper"

RSpec.describe SurveyTag, type: :liquid_tag do
  describe ".user_authorization_method_name" do
    subject(:result) { described_class.user_authorization_method_name }

    it { is_expected.to eq(nil) }
  end

  describe "#render" do
    let(:survey) { create(:survey) }
    let(:poll) { create(:poll, survey: survey) }
    let(:admin_user) { create(:user, :admin) }
    let(:source) { create(:article, user: admin_user) }
    let(:liquid_tag_options) { { source: source, user: admin_user } }

    it "renders survey with polls" do
      result = Liquid::Template.parse("{% survey #{survey.id} %}", liquid_tag_options).render
      expect(result).to include("survey_#{survey.id}")
      expect(result).to include(survey.title)
    end

    it "renders polls with supplementary text" do
      poll_with_supplementary = create(:poll, :with_supplementary_text, survey: survey)
      result = Liquid::Template.parse("{% survey #{survey.id} %}", liquid_tag_options).render

      expect(result).to include("option-supplementary-text")
      expect(result).to include("Desc 1")
    end

    it "renders scale polls with supplementary text on first and last options" do
      scale_poll = create(:poll, :scale_with_supplementary_text, survey: survey)
      result = Liquid::Template.parse("{% survey #{survey.id} %}", liquid_tag_options).render

      expect(result).to include("scale-supplementary-text-container")
      expect(result).to include("scale-supplementary-text-left")
      expect(result).to include("scale-supplementary-text-right")
      expect(result).to include("Very dissatisfied")
      expect(result).to include("Very satisfied")
    end

    it "renders scale polls with vertical supplementary text within scale value buttons" do
      scale_poll = create(:poll, :scale_with_supplementary_text, survey: survey)
      result = Liquid::Template.parse("{% survey #{survey.id} %}", liquid_tag_options).render

      expect(result).to include("scale-supplementary-text-vertical")
      expect(result).to include("scale-supplementary-text-horizontal")
      expect(result).to include("Very dissatisfied")
      expect(result).to include("Very satisfied")
    end

    it "allows non-admin users in non-article contexts" do
      regular_user = create(:user)
      result = Liquid::Template.parse("{% survey #{survey.id} %}", { source: nil, user: regular_user }).render
      expect(result).to include("survey_#{survey.id}")
    end
  end
end

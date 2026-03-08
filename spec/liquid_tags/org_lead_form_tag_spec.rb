require "rails_helper"

RSpec.describe OrgLeadFormTag, type: :liquid_tag do
  let(:organization) { create(:organization) }
  let(:lead_form) { create(:organization_lead_form, organization: organization, title: "Get Updates") }
  let(:liquid_tag_options) { { source: organization, user: nil } }

  def parse_tag(input, options = liquid_tag_options)
    Liquid::Template.parse("{% org_lead_form #{input} %}", options)
  end

  before do
    Liquid::Template.register_tag("org_lead_form", described_class)
  end

  context "when given a valid form ID" do
    it "renders the lead form" do
      liquid = parse_tag(lead_form.id.to_s)
      rendered = liquid.render
      expect(rendered).to include("Get Updates")
      expect(rendered).to include("ltag-org-lead-form")
    end

    it "includes data disclosure" do
      liquid = parse_tag(lead_form.id.to_s)
      rendered = liquid.render
      expect(rendered).to include(I18n.t("liquid_tags.org_lead_form_tag.data_shared"))
      expect(rendered).to include(I18n.t("liquid_tags.org_lead_form_tag.field_name"))
      expect(rendered).to include(I18n.t("liquid_tags.org_lead_form_tag.field_email"))
    end
  end

  context "when given an invalid form ID" do
    it "raises an error for non-numeric ID" do
      expect { parse_tag("abc") }.to raise_error(StandardError, I18n.t("liquid_tags.org_lead_form_tag.invalid_id"))
    end

    it "raises an error for non-existent form" do
      expect { parse_tag("999999") }.to raise_error(StandardError, I18n.t("liquid_tags.org_lead_form_tag.not_found"))
    end
  end

  context "when form is inactive" do
    it "raises an error" do
      lead_form.update!(active: false)
      expect { parse_tag(lead_form.id.to_s) }.to raise_error(StandardError, I18n.t("liquid_tags.org_lead_form_tag.inactive"))
    end
  end
end

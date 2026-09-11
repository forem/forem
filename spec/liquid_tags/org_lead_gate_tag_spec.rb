require "rails_helper"

RSpec.describe OrgLeadGateTag, type: :liquid_tag do
  let(:organization) { create(:organization) }
  let(:lead_form) { create(:organization_lead_form, organization: organization, title: "Watch the recording") }
  let(:liquid_tag_options) { { source: organization, user: nil } }

  def parse_tag(input = lead_form.id.to_s, content: "<p>Gated recording</p>", options: liquid_tag_options)
    Liquid::Template.parse(
      "{% org_lead_gate #{input} %}#{content}{% endorg_lead_gate %}",
      options,
    )
  end

  before do
    Liquid::Template.register_tag("org_lead_gate", described_class)
  end

  it "renders a signed-in lead gate with deferred content" do
    rendered = parse_tag.render

    expect(rendered).to include("ltag-org-lead-gate")
    expect(rendered).to include("Watch the recording")
    expect(rendered).to include("data-org-lead-gate-submit")
    expect(rendered).to include("name, email, username, company, and title")
    expect(rendered).to include('role="status" aria-live="polite"')
    expect(rendered).to include("<template data-org-lead-gate-content><p>Gated recording</p></template>")
    expect(rendered).not_to include('input name="email"')
  end

  it "checks for an existing authenticated submission before showing the form" do
    rendered = parse_tag.render

    expect(rendered).to include("/lead_submissions/check?form_ids=")
    expect(rendered).to include("csrfToken = data.csrf_token")
    expect(rendered).to include("if (data[formId])")
    expect(rendered).to include("document.body.getAttribute('data-user-status') !== 'logged-in'")
  end

  it "does not enable submission when the authenticated check fails" do
    rendered = parse_tag.render

    expect(rendered).to include("submitButton.disabled = !retryable")
    expect(rendered).to include("showError('Something went wrong. Please try again.', false)")
  end

  it "does not expose raw browser errors when submission fails" do
    rendered = parse_tag.render

    expect(rendered).to include("showError('Something went wrong. Please try again.', true)")
    expect(rendered).not_to include("showError(error.message")
  end

  it "preserves the deferred content through the Markdown renderer" do
    markdown = "{% org_lead_gate #{lead_form.id} %}**Gated recording**{% endorg_lead_gate %}"
    rendered = MarkdownProcessor::Parser.new(markdown, source: organization).finalize

    expect(rendered).to include("<template data-org-lead-gate-content><strong>Gated recording</strong></template>")
  end

  it "rejects a non-numeric form ID" do
    expect { parse_tag("abc") }
      .to raise_error(StandardError, I18n.t("liquid_tags.org_lead_gate_tag.invalid_id"))
  end

  it "rejects an inactive form" do
    lead_form.update!(active: false)

    expect { parse_tag }
      .to raise_error(StandardError, I18n.t("liquid_tags.org_lead_form_tag.inactive"))
  end

  it "rejects a form owned by another organization" do
    other_form = create(:organization_lead_form)

    expect { parse_tag(other_form.id.to_s) }
      .to raise_error(StandardError, I18n.t("liquid_tags.org_lead_form_tag.wrong_organization"))
  end

  it "rejects use outside an organization page" do
    options = { source: build(:billboard), user: nil }

    expect { parse_tag(options: options) }
      .to raise_error(LiquidTags::Errors::InvalidParseContext)
  end
end

class OrgLeadFormTag < LiquidTagBase
  PARTIAL = "liquids/org_lead_form".freeze

  def initialize(_tag_name, input, _parse_context)
    super
    @form_id = parse_form_id(input)
    @form = OrganizationLeadForm.find_by(id: @form_id)
    raise StandardError, I18n.t("liquid_tags.org_lead_form_tag.not_found") unless @form
    raise StandardError, I18n.t("liquid_tags.org_lead_form_tag.inactive") unless @form.active?
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: { form: @form },
    )
  end

  private

  def parse_form_id(input)
    id = Integer(input.strip, exception: false)
    raise StandardError, I18n.t("liquid_tags.org_lead_form_tag.invalid_id") unless id&.positive?

    id
  end
end

Liquid::Template.register_tag("org_lead_form", OrgLeadFormTag)

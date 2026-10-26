# A lead-generation gate for organization pages. The enclosed HTML remains in
# the public page source, so this must not be used as an authorization boundary.
class OrgLeadGateTag < Liquid::Block
  PARTIAL = "liquids/org_lead_gate".freeze
  VALID_CONTEXTS = %w[Organization].freeze

  def initialize(_tag_name, input, parse_context)
    super
    source = parse_context.partial_options[:source]
    validate_source(source)
    @form = find_form(input)

    return if @form.organization_id == source.id

    raise StandardError, I18n.t("liquid_tags.org_lead_form_tag.wrong_organization")
  end

  def render(context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: { form: @form, gated_content: super },
    )
  end

  private

  def find_form(input)
    form_id = Integer(input.strip, exception: false)
    unless form_id&.positive?
      raise StandardError, I18n.t("liquid_tags.org_lead_gate_tag.invalid_id")
    end

    form = OrganizationLeadForm.find_by(id: form_id)
    raise StandardError, I18n.t("liquid_tags.org_lead_form_tag.not_found") unless form
    raise StandardError, I18n.t("liquid_tags.org_lead_form_tag.inactive") unless form.active?

    form
  end

  def validate_source(source)
    unless source
      raise LiquidTags::Errors::InvalidParseContext,
            I18n.t("liquid_tags.liquid_tag_base.no_source_found")
    end

    return if VALID_CONTEXTS.include?(source.class.name)

    valid_contexts = VALID_CONTEXTS.map(&:pluralize).join(", ")
    error_message = I18n.t("liquid_tags.liquid_tag_base.invalid_context", valid: valid_contexts)
    raise LiquidTags::Errors::InvalidParseContext, error_message
  end
end

Liquid::Template.register_tag("org_lead_gate", OrgLeadGateTag)

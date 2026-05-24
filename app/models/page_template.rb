class PageTemplate < ApplicationRecord
  TEMPLATE_TYPE_OPTIONS = %w[contained full_within_layout nav_bar_included].freeze

  # Associations
  has_many :pages, dependent: :nullify
  has_many :forks, class_name: "PageTemplate", foreign_key: "forked_from_id", inverse_of: :forked_from,
                   dependent: :nullify
  belongs_to :forked_from, class_name: "PageTemplate", optional: true

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :template_type, inclusion: { in: TEMPLATE_TYPE_OPTIONS }
  validates :data_schema, presence: true
  validate :data_schema_format

  # Callbacks
  after_update :re_render_pages, if: :saved_change_to_body_or_markdown?

  # Scopes
  scope :root_templates, -> { where(forked_from_id: nil) }

  # Returns the schema fields as an array of hashes
  # Each field has: name, type, label, required, default_value
  def schema_fields
    data_schema["fields"] || []
  end

  # Render the template with the given data
  def render_with_data(data)
    content = body_markdown.presence || body_html
    return "" if content.blank?

    # Replace placeholders in the format {{field_name}}
    rendered = content.dup
    schema_fields.each do |field|
      field_name = field["name"]
      value = data[field_name].to_s
      rendered.gsub!("{{#{field_name}}}", value)
    end

    # Process markdown if using body_markdown
    if body_markdown.present?
      parsed = MarkdownProcessor::Parser.new(rendered)
      parsed.finalize
    else
      rendered
    end
  end

  # Validates that provided data matches the schema
  def validate_data(data)
    errors = []
    schema_fields.each do |field|
      field_name = field["name"]
      is_required = field["required"]

      if is_required && data[field_name].blank?
        errors << "#{field['label'] || field_name} is required"
      end
    end
    errors
  end

  # Create a fork of this template
  def fork(new_name:)
    PageTemplate.new(
      name: new_name,
      description: description,
      body_html: body_html,
      body_markdown: body_markdown,
      data_schema: data_schema.deep_dup,
      template_type: template_type,
      forked_from: self,
    )
  end

  # Get all ancestor templates
  def ancestors
    ancestors_list = []
    current = forked_from
    while current
      ancestors_list << current
      current = current.forked_from
    end
    ancestors_list
  end

  private

  def data_schema_format
    return if data_schema.blank?

    unless data_schema.is_a?(Hash)
      errors.add(:data_schema, "must be a valid JSON object")
      return
    end

    fields = data_schema["fields"]
    return if fields.blank?

    unless fields.is_a?(Array)
      errors.add(:data_schema, "fields must be an array")
      return
    end

    fields.each_with_index do |field, index|
      unless field.is_a?(Hash) && field["name"].present?
        errors.add(:data_schema, "field at index #{index} must have a name")
        next
      end

      allowed_types = %w[text textarea number url email select]
      if field["type"].present? && !allowed_types.include?(field["type"])
        errors.add(:data_schema, "field '#{field['name']}' has invalid type. Allowed: #{allowed_types.join(', ')}")
      end
    end
  end

  def saved_change_to_body_or_markdown?
    saved_change_to_body_html? || saved_change_to_body_markdown?
  end

  def re_render_pages
    PageTemplates::ReRenderPagesWorker.perform_async(id)
  end
end


class EmailSafeHtmlValidator < ActiveModel::EachValidator
  # Email-safe HTML tags that are widely supported across email clients
  ALLOWED_TAGS = %w[
    p br a strong b em i span div
    table tr td th tbody thead tfoot
    h1 h2 h3 h4 h5 h6
    ul ol li
    img
  ].freeze

  # Only allow inline styles and basic link attributes
  ALLOWED_ATTRIBUTES = %w[
    style href target title alt src width height
    align valign bgcolor border cellpadding cellspacing
  ].freeze

  def validate_each(record, attribute, value)
    return if value.blank?

    # Check for script tags or event handlers
    if value.match?(/(<script|javascript:|on\w+\s*=)/i)
      record.errors.add(
        attribute,
        "contains JavaScript or event handlers which are not allowed in emails"
      )
      return
    end

    # Check for external stylesheets or resources
    if value.match?(/(<link|<style|@import)/i)
      record.errors.add(
        attribute,
        "contains external stylesheets. Please use inline styles only"
      )
      return
    end

    # Sanitize and check if content changed significantly
    sanitized = sanitize_html(value)
    
    # If sanitization removed too much, warn the user
    if sanitized.length < (value.length * 0.5) && value.length > 100
      record.errors.add(
        attribute,
        "contains many unsupported HTML elements. Please use simple, email-safe HTML"
      )
    end
  end

  private

  def sanitize_html(html)
    # Use Rails sanitizer to clean HTML
    Rails::Html::SafeListSanitizer.new.sanitize(
      html,
      tags: ALLOWED_TAGS,
      attributes: ALLOWED_ATTRIBUTES
    ) || ""
  end
end

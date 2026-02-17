# Prevent Faker from generating characters that get HTML-encoded in responses,
# which causes string comparison failures in request specs.
#
# Characters like ' " & < > are HTML-escaped by Rails (e.g., O'Brien becomes
# O&#39;Brien), so `expect(response.body).to include(name)` fails.
#
# This patches Faker::Base.translate — the lowest-level method that all Faker
# generators use to pull strings from locale data — to strip HTML-unsafe
# characters from all generated fake data.
module FakerHtmlSafe
  HTML_UNSAFE_CHARS = "'\"&<>".freeze

  def translate(*args, **opts)
    result = super
    sanitize_faker_value(result)
  end

  private

  def sanitize_faker_value(value)
    case value
    when String
      value.tr(HTML_UNSAFE_CHARS, "")
    when Array
      value.map { |v| sanitize_faker_value(v) }
    else
      value
    end
  end
end

Faker::Base.singleton_class.prepend(FakerHtmlSafe)

RSpec::Matchers.define :validate_url_of do |attribute|
  match do
    actual = subject.is_a?(Class) ? subject.new : subject
    actual.send(:"#{attribute}=", "htp://invalidurl")
    expect(actual).to be_invalid
    @expected_message ||= I18n.t("errors.messages.url")
    expect(actual.errors.messages[attribute.to_sym]).to include(@expected_message)
  end
  chain :with_message do |message|
    @expected_message = message
  end
end

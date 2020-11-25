require "rails_helper"

RSpec.describe CleanHtml, type: :service do
  let(:html) do
    <<~HTML
      <img src="#{CleanHtml::MEDIUM_TRACKING_PIXEL}" />
      <p>#{CleanHtml::MEDIUM_CATCHPHRASE}</p>
    HTML
  end

  it "removes unwanted content", :aggregate_failures do
    expect(described_class.call(html)).not_to include("<img>")
    expect(described_class.call(html)).not_to include("<p>")
  end
end

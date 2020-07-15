require "rails_helper"

RSpec.describe Users::ProfileImageGenerator, type: :service do
  it "returns an emoji url" do
    expect(described_class.call).to start_with("https://emojipedia-us.s3")
  end
end

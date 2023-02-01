require "rails_helper"

RSpec.describe Users::ProfileImageGenerator, type: :service do
  it "returns an image file" do
    expect(described_class.call).to be_a(File)
  end
end

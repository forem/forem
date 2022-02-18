require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220217193509_add_award_badges.rb",
)

describe DataUpdateScripts::AddAwardBadges do
  let(:image_path) { Rails.root.join("spec/support/fixtures/images/image1.jpeg") }
  let(:badge_image) { Rack::Test::UploadedFile.new(image_path, "image/png") }

  before do
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Badge).to receive(:badge_image).and_return(badge_image)
    # rubocop:enable RSpec/AnyInstance
  end

  it "sets badges" do
    expect { described_class.new.run }.to change(Badge, :count).by(5)
  end

  it "does not set same badge twice" do
    expect do
      described_class.new.run
      described_class.new.run
    end.to change(Badge, :count).by(5)
  end
end

require "rails_helper"

RSpec.describe SearchKeyword, type: :model do
  let(:search_keyword) { create(:search_keyword) }

  it { is_expected.to validate_presence_of(:keyword) }
  it { is_expected.to validate_presence_of(:google_result_path) }
  it { is_expected.to validate_presence_of(:google_position) }
  it { is_expected.to validate_presence_of(:google_volume) }
  it { is_expected.to validate_presence_of(:google_difficulty) }
  it { is_expected.to validate_presence_of(:google_checked_at) }

  it "is valid with proper path" do
    search_keyword.google_result_path = "/hello/goodbye"
    expect(search_keyword).to be_valid
  end

  it "is invalid with improper path" do
    search_keyword.google_result_path = "hello/goodbye"
    expect(search_keyword).not_to be_valid
  end
end

require "rails_helper"

RSpec.describe RequestRedirect, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:original_url) }
    it { is_expected.to validate_presence_of(:destination_url) }
    it { is_expected.to validate_presence_of(:request_domain) }

    describe "uniqueness" do
      subject { described_class.new(original_url: "/path", destination_url: "http://example.com", request_domain: "blog.com") }
      
      it { is_expected.to validate_uniqueness_of(:original_url).scoped_to(:request_domain) }
    end
  end
end

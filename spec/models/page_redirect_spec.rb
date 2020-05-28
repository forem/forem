require "rails_helper"

RSpec.describe PageRedirect, type: :model do
  subject { build(:page_redirect) }

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:old_slug) }
    it { is_expected.to validate_presence_of(:old_slug) }
    it { is_expected.to validate_presence_of(:new_slug) }
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_inclusion_of(:source).in_array(described_class::SOURCES) }
  end

  describe "before_save" do
    it "increments version by 1 if new_slug is updated" do
      page_redirect = create(:page_redirect)
      expect(page_redirect.version).to eq 1
      page_redirect.update(new_slug: "/some-new-slug")
      expect(page_redirect.version).to eq 2
    end

    it "does not increment version new_slug is not updated" do
      page_redirect = create(:page_redirect)
      expect(page_redirect.version).to eq 1
      page_redirect.update(old_slug: "/some-old-slug")
      expect(page_redirect.version).to eq 1
    end
  end
end

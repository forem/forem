require "rails_helper"

RSpec.describe PageRedirect, type: :model do
  subject { build(:page_redirect) }

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:old_path) }
    it { is_expected.to validate_presence_of(:old_path) }
    it { is_expected.to validate_presence_of(:new_path) }
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_inclusion_of(:source).in_array(%w[admin service]) }
  end

  describe "before_save" do
    it "increments the version by 1 if the new_path is updated" do
      page_redirect = create(:page_redirect)
      expect(page_redirect.version).to eq 1
      page_redirect.update(new_path: "/some-new-path")
      expect(page_redirect.version).to eq 2
    end

    it "does not increment the version if a field other than new_path is updated" do
      page_redirect = create(:page_redirect)
      expect(page_redirect.version).to eq 1
      page_redirect.update(old_path: "/some-old-path")
      expect(page_redirect.version).to eq 1
    end
  end
end

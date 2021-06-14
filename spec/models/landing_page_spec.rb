require "rails_helper"

RSpec.describe LandingPage, type: :model do
  describe ".exists?" do
    it "returns false if there is no landing page" do
      expect(described_class.exists?).to be(false)
    end

    it "returns true if there is a landing page" do
      create(:page, landing_page: true)

      expect(described_class.exists?).to be(true)
    end
  end

  describe ".id" do
    it "returns nil if there is no pinned article" do
      expect(described_class.id).to be_nil
    end

    it "returns the id of the landing page" do
      page = create(:page, landing_page: true)

      expect(described_class.id).to eq(page.id)
    end
  end

  describe ".get" do
    it "returns nil if there is no landing page" do
      expect(described_class.get).to be_nil
    end

    it "returns the landing page" do
      page = create(:page, landing_page: true)

      expect(described_class.get.id).to eq(page.id)
    end
  end

  describe ".set" do
    it "sets the given page as landing page" do
      page = create(:page)

      described_class.set(page)

      expect(described_class.get.id).to eq(page.id)
    end

    it "sets the .landing_page attribute to true" do
      page = create(:page)

      expect do
        described_class.set(page)
      end.to change(page, :landing_page).from(false).to(true)
    end

    it "overrides the previous landing page", :aggregate_failures do
      previous_landing_page = create(:page, landing_page: true)
      page = create(:page)

      expect(described_class.get.id).to eq(previous_landing_page.id)

      described_class.set(page)

      expect(described_class.get.id).to eq(page.id)
    end
  end

  describe ".remove" do
    it "works even if there is no landing page" do
      expect { described_class.remove }.not_to raise_error
    end

    it "removes the current landing page" do
      create(:page, landing_page: true)

      described_class.remove

      expect(described_class.exists?).to be(false)
    end
  end
end

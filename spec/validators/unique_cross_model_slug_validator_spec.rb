require "rails_helper"

RSpec.describe UniqueCrossModelSlugValidator do
  subject(:record) { validatable.new.tap { |m| m.name = name } }

  let(:validatable) do
    Class.new do
      def self.name
        "Validatable"
      end
      include ActiveModel::Validations
      attr_accessor :name

      validates :name, unique_cross_model_slug: true
    end
  end

  context "when name includes sitemap-" do
    let(:name) { "sitemap-happy" }

    it { is_expected.not_to be_valid }
  end

  context "when name exists in User model" do
    let(:user) { create(:user) }
    let(:name) { user.username }

    it { is_expected.not_to be_valid }
  end

  context "when name exists in Organization model" do
    let(:org) { create(:organization) }
    let(:name) { org.slug }

    it { is_expected.not_to be_valid }
  end

  context "when name exists in Podcast model" do
    let(:org) { create(:podcast) }
    let(:name) { org.slug }

    it { is_expected.not_to be_valid }
  end

  context "when name exists in Page model" do
    let(:org) { create(:page) }
    let(:name) { org.slug }

    it { is_expected.not_to be_valid }
  end

  context "when name is something different" do
    let(:org) { create(:organization) }
    let(:name) { "not-#{org.slug}" }

    it { is_expected.to be_valid }
  end
end

require "rails_helper"

RSpec.describe CrossModelSlugValidator do
  subject(:record) { validatable.new.tap { |m| m.name = name } }

  let(:validatable) do
    Class.new do
      def self.name
        "Validatable"
      end
      include ActiveModel::Validations
      attr_accessor :name

      def initialize
        @enforce_validation = true
      end

      def name_changed?
        true
      end

      attr_accessor :enforce_validation
      alias_method :enforce_validation?, :enforce_validation

      validates :name, cross_model_slug: true, if: :enforce_validation?
    end
  end

  context "when if option is false" do
    let(:name) { "sitemap-happy" }

    before { record.enforce_validation = false }

    it { is_expected.to be_valid }
  end

  context "when name includes sitemap-" do
    let(:name) { "sitemap-happy" }

    it { is_expected.not_to be_valid }
  end

  context "when name is a ReservedWord" do
    let(:name) { "members" }

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

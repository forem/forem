require "rails_helper"

RSpec.describe EmojiOnlyValidator do
  subject(:record) { validatable.new.tap { |m| m.name = name } }

  let(:validatable) do
    Class.new do
      def self.name
        "👍"
      end
      include ActiveModel::Validations
      attr_accessor :name

      def initialize
        @enforce_validation = true
      end

      attr_accessor :enforce_validation
      alias_method :enforce_validation?, :enforce_validation

      validates :name, emoji_only: true, if: :enforce_validation?
    end
  end

  context "when if option is false" do
    let(:name) { "not-an-emoji" }

    before { record.enforce_validation = false }

    it { is_expected.to be_valid }
  end

  context "when name includes non-emoji" do
    let(:name) { "not-an-emoji" }

    it { is_expected.not_to be_valid }
  end

  context "when name is an emoji" do
    let(:name) { "🍀" }

    it { is_expected.to be_valid }
  end

  context "when name is nil" do
    let(:name) { nil }

    it "does not raise no method error" do
      expect { record.valid? }.not_to raise_error
    end

    it { is_expected.to be_valid }
  end

  context "when name is empty" do
    let(:name) { "" }

    it { is_expected.to be_valid }
  end
end

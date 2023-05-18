require "rails_helper"

RSpec.describe Search::FeedContent::RequestedResourceType, type: :service do
  subject(:requested_resource) do
    described_class.new(feed_params: feed_params)
  end

  describe "#class_name" do
    let(:feed_params) do
      {
        class_name: double
      }
    end

    it "is a string involved by ActiveSupport::StringInquirer wrapper" do
      expect(requested_resource.class_name.class.name)
        .to eq("ActiveSupport::StringInquirer")
    end
  end

  describe "#sorted_articles_request?" do
    context "when the class is Article, search fields are blank and sort_by is present" do
      let(:feed_params) do
        {
          class_name: "Article",
          search_fields: "",
          sort_by: double
        }
      end

      it "returns true" do
        expect(requested_resource.sorted_articles_request?).to be true
      end
    end

    context "when class is not Article" do
      let(:feed_params) do
        {
          class_name: "A different class",
          search_fields: "",
          sort_by: double
        }
      end

      it "returns false" do
        expect(requested_resource.sorted_articles_request?).to be false
      end
    end
  end

  describe "#empty_or_articles_not_sorted?" do
    context "when class name is blank and is not a sorted_articles type" do
      let(:feed_params) do
        {
          class_name: "",
          sort_by: nil
        }
      end

      it "returns true" do
        expect(requested_resource.empty_or_articles_not_sorted?).to be true
      end
    end
  end

  describe "#invalid?" do
    context "when class_name is provided but is unknown" do
      let(:feed_params) do
        {
          class_name: "Unknown class"
        }
      end

      it "returns true" do
        expect(requested_resource.invalid?).to be(true)
      end
    end

    context "when class_name is empty" do
      let(:feed_params) do
        {
          class_name: ""
        }
      end

      it "returns false since is a valid param" do
        expect(requested_resource.invalid?).to be(false)
      end
    end

    context "when class_name is filled and valid" do
      let(:feed_params) do
        {
          class_name: SearchResources::FeedContent::Classes.all.first
        }
      end

      it "returns false" do
        expect(requested_resource.invalid?).to be(false)
      end
    end
  end
end

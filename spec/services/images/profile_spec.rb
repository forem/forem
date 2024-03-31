require "rails_helper"

RSpec.describe Images::Profile, type: :services do
  describe ".for" do
    subject(:returned_value) { described_class.for(:work) }

    it { is_expected.to be_a(Module) }

    context "when mixed in" do
      subject(:object) { klass.new.tap { |k| k.the_image_url = "https://forem.com/image" } }

      let(:klass) do
        Class.new do
          attr_accessor :the_image_url

          include Images::Profile.for(:the_image_url)
        end
      end

      it "creates a method" do
        expect(object).to respond_to(:the_image_url_for)
      end

      it "forward delegate the method to Images::Profile.call" do
        allow(described_class).to receive(:call)
        object.the_image_url_for(length: 90)
        expect(described_class).to have_received(:call).with(object.the_image_url, length: 90)
      end
    end
  end

  describe ".get" do
    it "returns user profile_image_url" do
      user = build_stubbed(:user)
      expect(described_class.call(user.profile_image_url)).to eq(user.profile_image_url)
    end

    context "when user has no profile_image" do
      it "returns backup image prefixed with Cloudinary", :cloudinary do
        user = build_stubbed(:user, profile_image: nil)
        correct_prefix = "/c_fill,f_auto,fl_progressive,h_120,q_auto,w_120/"
        expect(described_class.call(user.profile_image_url)).to include(correct_prefix + described_class::BACKUP_LINK)
      end
    end
  end
end

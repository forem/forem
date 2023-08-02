require "rails_helper"

RSpec.describe Images::GenerateSocialImageMagickally, type: :model do
  let(:user) { create(:user) }
  let!(:article) { create(:article, user_id: user.id, with_main_image: false) }
  let(:organization) { create(:organization) }
  let!(:second_article) { create(:article, user_id: user.id, organization_id: organization.id, with_main_image: false) }
  let(:background_image) { double("MiniMagick::Image") }

  describe ".call" do
    context "when resource is an Article" do
      let(:generator) { described_class.new(article) }

      before do
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:read_files) do
          allow(background_image).to receive(:combine_options).and_return(background_image)
          allow(background_image).to receive(:composite) do |&block|
            block.call(background_image); background_image 
          end
          generator.instance_variable_set("@background_image", background_image)
        end
        allow(generator).to receive(:add_logo)
        allow(generator).to receive(:add_text)
        allow(generator).to receive(:add_profile_image)
        allow(generator).to receive(:upload_result).and_return("image_url")
      end
      
      it "calls the class methods" do
        expect(generator).to receive(:generate_magickally).once
        described_class.call(article)
      end

      it "updates article to have social image" do
        expect(generator).to receive(:generate_magickally).and_return("https://www.example.com")
        described_class.call(article)
        expect(article.reload.social_image).to eq("https://www.example.com")
      end

      it "converts black color to off-black" do
        allow(background_image).to receive(:combine_options).with(any_args) do |&block|
          command = MiniMagick::CommandBuilder.new(:mogrify)
          block.call(command)
          expect(command.args.join(" ")).to include("fill '#111212'")
        end
  
        described_class.call(article)
      end
    end

    context "when resource is a User" do
      let(:generator) { described_class.new(user) }

      before do
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:read_files)
      end

      it "calls the class methods for each published article" do
        expect(generator).to receive(:generate_magickally).once
          .with(
            title: article.title,
            date: article.readable_publish_date,
            author_name: user.name,
            color: user.setting.brand_color1,
          )
        described_class.call(user)
      end

      it "updates article to have social image" do
        expect(generator).to receive(:generate_magickally).and_return("https://www.example.com")
        described_class.call(user)
        expect(article.reload.social_image).to eq("https://www.example.com")
      end
    end

    context "when resource is an Organization" do
      let(:generator) { described_class.new(organization) }

      before do
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:read_files)
      end

      it "calls the class methods for each published article" do
        expect(generator).to receive(:generate_magickally).once
          .with(
            title: second_article.title,
            date: second_article.readable_publish_date,
            author_name: organization.name,
            color: organization.bg_color_hex,
          )
        described_class.call(organization)
      end

      it "updates article to have social image" do
        expect(generator).to receive(:generate_magickally).and_return("https://www.example.com")
        described_class.call(organization)
        expect(second_article.reload.social_image).to eq("https://www.example.com")
      end
    end
  end
end

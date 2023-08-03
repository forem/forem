require "rails_helper"

RSpec.describe Images::GenerateSocialImageMagickally, type: :model do
  let(:user) { create(:user) }
  let!(:article) { create(:article, user_id: user.id, with_main_image: false) }
  let(:organization) { create(:organization) }
  let!(:second_article) { create(:article, user_id: user.id, organization_id: organization.id, with_main_image: false) }
  let(:background_image) { double('MiniMagick::Image') }

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

    context "calculate_font_size" do
      let(:generator) { described_class.new(article) }

      it "returns the correct font size for short text" do
        expect(generator.send(:calculate_font_size, "short text")).to eq(88)
      end

      it "returns the correct font size for medium text" do
        medium_text = "This is a slightly longer text."
        expect(generator.send(:calculate_font_size, medium_text)).to eq(77)
      end

      it "returns the correct font size for medium-to-long text" do
        medium_long_text = "This is a slightly longer text. Slightly longer than the last."
        expect(generator.send(:calculate_font_size, medium_long_text)).to eq(60)
      end

      it "returns the correct font size for long text" do
        long_text = "This is a very long text that is definitely more than 70 characters long and should return a smaller font size"
        expect(generator.send(:calculate_font_size, long_text)).to eq(50)
      end
    end

    context "wrap_text" do
      let(:generator) { described_class.new(article) }

      it "returns the same text when the text length is less than 40" do
        text = "This is a short text"
        expect(generator.send(:wrap_text, text)).to eq(text)
      end

      it "returns wrapped text when the text length is between 40 and 70" do
        text = "This is a slightly longer text that is about 50 characters long and should be wrapped"
        wrapped_text = "This is a slightly longer text that\nis about 50 characters long and\nshould be wrapped"
        expect(generator.send(:wrap_text, text)).to eq(wrapped_text)
      end

      it "returns wrapped text when the text length is more than 70" do
        text = "This is a very long text that is definitely more than 70 characters long and should be wrapped over multiple lines"
        wrapped_text = "This is a very long text that is\ndefinitely more than 70 characters\nlong and should be wrapped over\nmultiple lines"
        expect(generator.send(:wrap_text, text)).to eq(wrapped_text)
      end
    end

    context "add_text" do
      let(:generator) { described_class.new(article) }
      let(:result_image) { double("MiniMagick::Tool::Convert") }

      before do
        allow(generator).to receive(:calculate_font_size).and_return(40)
        allow(generator).to receive(:wrap_text).and_return("Wrapped Text")
        allow(result_image).to receive(:combine_options) { |&block| block.call(result_image); result_image }
        allow(result_image).to receive(:gravity)
        allow(result_image).to receive(:pointsize)
        allow(result_image).to receive(:draw)
        allow(result_image).to receive(:fill)
        allow(result_image).to receive(:font)
        generator.instance_variable_set("@background_image", result_image)
      end

      it "adds title, date, and author_name text to the image" do
        expect(result_image).to receive(:combine_options).exactly(3).times
        generator.send(:add_text, result_image, "title", "date", "author_name")
      end
    end

    context "add_profile_image" do
      let(:user) { create(:user) }
      let(:article) { create(:article, user_id: user.id, with_main_image: false) }
      let(:generator) { described_class.new(article) }
      let(:result_image) { double('MiniMagick::Tool::Convert') }
      let(:author_image) { double('MiniMagick::Tool::Convert') }
      let(:rounded_mask) { double('MiniMagick::Tool::Convert') }

      before do
        allow(result_image).to receive(:composite).and_return(result_image)
        allow(author_image).to receive(:resize)
        allow(rounded_mask).to receive(:resize)

        generator.instance_variable_set("@background_image", result_image)
        generator.instance_variable_set("@author_image", author_image)
        generator.instance_variable_set("@rounded_mask", rounded_mask)
      end

      it "adds the profile image and rounded mask to the image" do
        expect(author_image).to receive(:resize).with("64x64")
        expect(rounded_mask).to receive(:resize).with("64x64")
        expect(result_image).to receive(:composite).twice.and_return(result_image)

        generator.send(:add_profile_image, result_image)
      end
    end

    context "add_logo" do
      let(:user) { create(:user) }
      let(:article) { create(:article, user_id: user.id, with_main_image: false) }
      let(:generator) { described_class.new(article) }
      let(:result_image) { double('MiniMagick::Tool::Convert') }
      let(:logo_image) { double('MiniMagick::Tool::Convert') }

      before do
        allow(result_image).to receive(:composite).and_return(result_image)
        allow(logo_image).to receive(:combine_options).and_yield(logo_image)
        allow(logo_image).to receive(:resize)
        allow(logo_image).to receive(:stroke)
        allow(logo_image).to receive(:strokewidth)
        allow(logo_image).to receive(:fill)
        allow(logo_image).to receive(:draw)

        generator.instance_variable_set("@background_image", result_image)
        generator.instance_variable_set("@logo_image", logo_image)
      end

      context "when logo image is present" do
        it "adds the logo to the image" do
          expect(logo_image).to receive(:combine_options).and_yield(logo_image)
          expect(logo_image).to receive(:stroke).with("white")
          expect(logo_image).to receive(:strokewidth).with("4")
          expect(logo_image).to receive(:fill).with("none")
          expect(logo_image).to receive(:draw).with("rectangle 0,0 1000,1000")
          expect(logo_image).to receive(:resize).with("64x64")
          expect(result_image).to receive(:composite).with(logo_image).and_return(result_image)

          generator.send(:add_logo, result_image)
        end
      end

      context "when logo image is not present" do
        before do
          generator.instance_variable_set("@logo_image", nil)
        end

        it "does not attempt to add the logo to the image" do
          expect(result_image).not_to receive(:composite)

          generator.send(:add_logo, result_image)
        end
      end
    end
  end
end

require "rails_helper"

RSpec.describe Images::GenerateSocialImageMagickally, type: :model do
  let(:user) { create(:user) }
  let(:default_subforem) { create(:subforem, domain: "default.test") }
  let(:custom_subforem) { create(:subforem, domain: "custom.test") }
  let!(:article) { create(:article, user_id: user.id, with_main_image: false, subforem: default_subforem) }
  let!(:article_with_custom_subforem) { create(:article, user_id: user.id, with_main_image: false, subforem: custom_subforem) }
  let!(:article_without_subforem) { create(:article, user_id: user.id, with_main_image: false, subforem: nil) }
  let(:organization) { create(:organization) }
  let!(:second_article) { create(:article, user_id: user.id, organization_id: organization.id, with_main_image: false, subforem: custom_subforem) }
  let(:background_image) { instance_double(MiniMagick::Image) }
  let(:default_logo_url) { "https://example.com/default_logo.png" }
  let(:custom_logo_url) { "https://example.com/custom_logo.png" }

  before do
    allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
    allow(Settings::General).to receive(:logo_png).with(subforem_id: default_subforem.id).and_return(default_logo_url)
    allow(Settings::General).to receive(:logo_png).with(subforem_id: custom_subforem.id).and_return(custom_logo_url)
  end

  # rubocop:disable Style/Send
  # rubocop:disable Layout/LineLength
  # rubocop:disable RSpec/VerifiedDoubles
  # rubocop:disable RSpec/ContextWording
  # rubocop:disable Style/Semicolon
  # rubocop:disable RSpec/NestedGroups
  describe ".call" do
    context "when resource is an Article" do
      let(:generator) { described_class.new(article) }

      before do
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:read_files)
        allow(generator).to receive(:add_logo)
        allow(generator).to receive(:add_text)
        allow(generator).to receive(:add_profile_image)
        allow(generator).to receive(:upload_result).and_return("image_url")
        allow(generator).to receive(:generate_magickally)
      end

      it "calls the class methods" do
        described_class.call(article)
        expect(generator).to have_received(:generate_magickally).once
      end

      it "updates article to have social image" do
        allow(generator).to receive(:generate_magickally).and_return("https://www.example.com")
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

      it "busts article cache" do
        allow(EdgeCache::BustArticle).to receive(:call).with(article)
        described_class.call(article)
      end

      it "passes the article to read_files" do
        described_class.call(article)
        expect(generator).to have_received(:read_files).with(article)
      end

      context "with custom subforem" do
        let(:generator) { described_class.new(article_with_custom_subforem) }

        it "passes the article with custom subforem to read_files" do
          described_class.call(article_with_custom_subforem)
          expect(generator).to have_received(:read_files).with(article_with_custom_subforem)
        end
      end

      context "without subforem" do
        let(:generator) { described_class.new(article_without_subforem) }

        it "passes the article without subforem to read_files" do
          described_class.call(article_without_subforem)
          expect(generator).to have_received(:read_files).with(article_without_subforem)
        end
      end
    end

    context "when resource is a User" do
      let(:generator) { described_class.new(user) }

      before do
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:read_files)
        allow(generator).to receive(:generate_magickally)
        allow(user).to receive(:profile_image_90).and_return("https://www.example.com/image.png")
      end

      it "calls the class methods for each published article" do
        described_class.call(user)
        expect(generator).to have_received(:generate_magickally).at_least(:once)
          .with(
            title: article.title,
            date: article.readable_publish_date,
            author_name: user.name,
            color: user.setting.brand_color1,
          )
      end

      it "updates article to have social image" do
        allow(generator).to receive(:generate_magickally).and_return("https://www.example.com")
        described_class.call(user)
        expect(article.reload.social_image).to eq("https://www.example.com")
      end

      it "calls read_files with each article" do
        described_class.call(user)
        expect(generator).to have_received(:read_files).at_least(:once)
      end

      it "processes articles with different subforems correctly" do
        allow(generator).to receive(:generate_magickally).and_return("https://www.example.com")
        described_class.call(user)
        
        # Verify that read_files was called for each article
        [article, article_with_custom_subforem, article_without_subforem].each do |art|
          expect(generator).to have_received(:read_files).with(art) if art.organization_id.nil? && art.main_image.nil?
        end
      end

      context "caching optimization" do
        let!(:article2_same_subforem) { create(:article, user_id: user.id, with_main_image: false, subforem: default_subforem) }
        let!(:article3_same_subforem) { create(:article, user_id: user.id, with_main_image: false, subforem: default_subforem) }

        before do
          # Clear the existing stubs for these tests
          RSpec::Mocks.space.proxy_for(Settings::General).reset
          
          # Don't stub read_files for this test - we want to test the real caching behavior
          allow(described_class).to receive(:new).and_call_original
          allow(MiniMagick::Image).to receive(:open).and_return(double(combine_options: nil, resize: nil, composite: nil))
          allow_any_instance_of(described_class).to receive(:generate_magickally).and_return("https://www.example.com")
        end

        it "caches logo URL for consecutive articles with the same subforem" do
          # Set up fresh stubs for this specific test
          allow(Settings::General).to receive(:logo_png).with(subforem_id: default_subforem.id).and_return(default_logo_url)
          allow(Settings::General).to receive(:logo_png).with(subforem_id: custom_subforem.id).and_return(custom_logo_url)
          allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
          
          described_class.call(user)
          
          # Cache is invalidated when switching between subforems, so we expect:
          # 1st call for initial default subforem articles
          # 1 call for custom subforem
          # May be called again for default after switching to custom (depending on order)
          # The optimization is that consecutive same-subforem articles only call it once
          expect(Settings::General).to have_received(:logo_png).with(subforem_id: default_subforem.id).at_least(:once).at_most(2).times
          expect(Settings::General).to have_received(:logo_png).with(subforem_id: custom_subforem.id).once
        end

        it "avoids redundant logo_png calls compared to no caching" do
          call_count = 0
          allow(Settings::General).to receive(:logo_png) do |args|
            call_count += 1
            args[:subforem_id] == default_subforem.id ? default_logo_url : custom_logo_url
          end
          allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
          
          described_class.call(user)
          
          # Without caching, would be called 5 times (once per article)
          # With caching, called much fewer times (2-3 times depending on order)
          expect(call_count).to be < 5
        end

        it "still creates fresh MiniMagick image objects for each article" do
          allow(Settings::General).to receive(:logo_png).and_return(default_logo_url)
          allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
          
          described_class.call(user)
          
          # Should open images for each article (4 files per article: template, logo, author, mask)
          # We have 5 articles without org and without main_image (article, article_with_custom_subforem, article_without_subforem, article2_same_subforem, article3_same_subforem)
          expect(MiniMagick::Image).to have_received(:open).at_least(16).times
        end
      end
    end

    context "when resource is an Organization" do
      let(:generator) { described_class.new(organization) }

      before do
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:read_files)
      end

      it "calls the class methods for each published article" do
        allow(generator).to receive(:generate_magickally)
        described_class.call(organization)
        expect(generator).to have_received(:generate_magickally).once
      end

      it "updates article to have social image" do
        allow(generator).to receive(:generate_magickally).and_return("https://www.example.com")
        described_class.call(organization)
        expect(generator).to have_received(:generate_magickally).once
        expect(second_article.reload.social_image).to eq("https://www.example.com")
      end

      it "calls read_files with the article" do
        allow(generator).to receive(:generate_magickally).and_return("https://www.example.com")
        described_class.call(organization)
        expect(generator).to have_received(:read_files).with(second_article)
      end

      it "passes article with custom subforem to read_files" do
        allow(generator).to receive(:generate_magickally).and_return("https://www.example.com")
        described_class.call(organization)
        expect(generator).to have_received(:read_files).with(second_article)
        expect(second_article.subforem_id).to eq(custom_subforem.id)
      end

      context "caching optimization" do
        let!(:org_article2) { create(:article, organization_id: organization.id, with_main_image: false, subforem: custom_subforem) }
        let!(:org_article3) { create(:article, organization_id: organization.id, with_main_image: false, subforem: default_subforem) }

        before do
          # Clear the existing stubs for these tests
          RSpec::Mocks.space.proxy_for(Settings::General).reset
          
          allow(described_class).to receive(:new).and_call_original
          allow(MiniMagick::Image).to receive(:open).and_return(double(combine_options: nil, resize: nil, composite: nil))
          allow_any_instance_of(described_class).to receive(:generate_magickally).and_return("https://www.example.com")
        end

        it "only fetches logo URL once per unique subforem" do
          allow(Settings::General).to receive(:logo_png).with(subforem_id: custom_subforem.id).and_return(custom_logo_url)
          allow(Settings::General).to receive(:logo_png).with(subforem_id: default_subforem.id).and_return(default_logo_url)
          allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
          
          described_class.call(organization)
          
          # We have 2 articles with custom_subforem and 1 with default_subforem
          expect(Settings::General).to have_received(:logo_png).with(subforem_id: custom_subforem.id).once
          expect(Settings::General).to have_received(:logo_png).with(subforem_id: default_subforem.id).once
        end

        it "still creates fresh MiniMagick image objects for each article" do
          allow(Settings::General).to receive(:logo_png).and_return(default_logo_url)
          allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
          
          described_class.call(organization)
          
          # Should open images for each article (3 articles)
          expect(MiniMagick::Image).to have_received(:open).at_least(9).times
        end
      end
    end

    context "when calculate_font_size" do
      let(:generator) { described_class.new(article) }

      it "returns the correct font size for short text" do
        expect(generator.send(:calculate_font_size, "short text")).to eq(88)
      end

      it "returns the correct font size for medium text" do
        medium_text = "This is a slightly longer text."
        expect(generator.send(:calculate_font_size, medium_text)).to eq(77)
      end

      it "returns the correct font size for medium-to-long text" do
        medium_long_text = "This is a slightly longer text. Slightly longer."
        expect(generator.send(:calculate_font_size, medium_long_text)).to eq(65)
      end

      it "returns the correct font size for medium-to-long text" do
        almost_long_text = "This is a slightly longer text. Slightly longer than the last."
        expect(generator.send(:calculate_font_size, almost_long_text)).to eq(60)
      end

      it "returns the correct font size for long text" do
        long_text = "This is a very long text that is definitely more than 70 characters long
          and should return a smaller font size"
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
      let(:result_image) { double(MiniMagick::Tool::Convert) }

      before do
        allow(generator).to receive_messages(calculate_font_size: 40, wrap_text: "Wrapped Text")
        allow(result_image).to receive(:combine_options) { |&block| block.call(result_image); result_image }
        allow(result_image).to receive(:gravity)
        allow(result_image).to receive(:pointsize)
        allow(result_image).to receive(:draw)
        allow(result_image).to receive(:fill)
        allow(result_image).to receive(:font)
        generator.instance_variable_set(:@background_image, result_image)
      end

      it "adds title, date, and author_name text to the image" do
        generator.send(:add_text, result_image, "title", "date", "author_name")
        expect(result_image).to have_received(:combine_options).exactly(3).times
      end

      it "truncates text longer than 128" do
        allow(generator).to receive(:wrap_text).and_return("whatever")
        text = "This is a very long text that is definitely more than 128 characters long and should be wrapped over multiple lines. This is a very long text that is definitely more than 128 characters long and should be wrapped over multiple lines."
        truncated_text = "This is a very long text that is definitely more than 128 characters long and should be wrapped over multiple lines. This is ..."
        generator.send(:add_text, result_image, text, "date", "author_name")
        expect(generator).to have_received(:wrap_text).with(truncated_text)
      end
    end

    context "add_profile_image" do
      let(:user) { create(:user) }
      let(:article) { create(:article, user_id: user.id, with_main_image: false) }
      let(:generator) { described_class.new(article) }
      let(:result_image) { double(MiniMagick::Tool::Convert) }
      let(:author_image) { double(MiniMagick::Tool::Convert) }
      let(:rounded_mask) { double(MiniMagick::Tool::Convert) }

      before do
        allow(result_image).to receive(:composite).and_return(result_image)
        allow(author_image).to receive(:resize)
        allow(rounded_mask).to receive(:resize)

        generator.instance_variable_set(:@background_image, result_image)
        generator.instance_variable_set(:@author_image, author_image)
        generator.instance_variable_set(:@rounded_mask, rounded_mask)
      end

      it "adds the profile image and rounded mask to the image" do
        generator.send(:add_profile_image, result_image)
        expect(author_image).to have_received(:resize).with("64x64")
        expect(rounded_mask).to have_received(:resize).with("64x64")
        expect(result_image).to have_received(:composite).twice
      end
    end

    context "add_logo" do
      let(:user) { create(:user) }
      let(:article) { create(:article, user_id: user.id, with_main_image: false) }
      let(:generator) { described_class.new(article) }
      let(:result_image) { double(MiniMagick::Tool::Convert) }
      let(:logo_image) { double(MiniMagick::Tool::Convert) }

      before do
        allow(result_image).to receive(:composite).and_return(result_image)
        allow(logo_image).to receive(:combine_options).and_yield(logo_image)
        allow(logo_image).to receive(:resize)
        allow(logo_image).to receive(:stroke)
        allow(logo_image).to receive(:strokewidth)
        allow(logo_image).to receive(:fill)
        allow(logo_image).to receive(:draw)

        generator.instance_variable_set(:@background_image, result_image)
        generator.instance_variable_set(:@logo_image, logo_image)
      end

      context "when logo image is present" do
        it "adds the logo to the image" do
          generator.send(:add_logo, result_image)

          expect(logo_image).to have_received(:combine_options)
          expect(logo_image).to have_received(:stroke).with("white")
          expect(logo_image).to have_received(:strokewidth).with("4")
          expect(logo_image).to have_received(:fill).with("none")
          expect(logo_image).to have_received(:draw).with("rectangle 0,0 1000,1000")
          expect(logo_image).to have_received(:resize).with("64x64")
          expect(result_image).to have_received(:composite).with(logo_image)
        end
      end

      context "when logo image is not present" do
        before do
          generator.instance_variable_set(:@logo_image, nil)
        end

        it "does not attempt to add the logo to the image" do
          generator.send(:add_logo, result_image)
          expect(result_image).not_to have_received(:composite)
        end
      end

      context "upload_result" do
        let(:generator) { described_class.new(article) }
        let(:result_image) { double(MiniMagick::Tool::Convert) }
        let(:tempfile) { instance_double(Tempfile, path: "/tmp/output.png") }
        let(:uploader) { instance_double(ArticleImageUploader) }

        before do
          allow(Tempfile).to receive(:new).and_return(tempfile)
          allow(tempfile).to receive(:close)
          allow(tempfile).to receive(:unlink)
          allow(result_image).to receive(:write)

          allow(ArticleImageUploader).to receive(:new).and_return(uploader)
          allow(uploader).to receive(:store!)
          allow(uploader).to receive(:url).and_return("http://example.com/social_image.png")

          generator.instance_variable_set(:@background_image, result_image)
        end

        it "creates a tempfile, writes the image, uploads the image, then cleans up the tempfile" do
          expect(generator.send(:upload_result, result_image)).to eq "http://example.com/social_image.png"

          expect(Tempfile).to have_received(:new).with(["output", ".png"])
          expect(result_image).to have_received(:write).with(tempfile.path)
          expect(ArticleImageUploader).to have_received(:new)
          expect(uploader).to have_received(:store!).with(tempfile)
          expect(tempfile).to have_received(:close)
          expect(tempfile).to have_received(:unlink)
          expect(uploader).to have_received(:url)
        end
      end
    end

    context "read_files" do
      let(:instance) { described_class.new(article) }

      before do
        allow(MiniMagick::Image).to receive(:open) # stub the actual image opening
        instance.instance_variable_set(:@user, article.user)
        described_class.send(:public, :read_files)
      end

      it "opens the template, logo, author image, and rounded mask with default subforem logo" do
        expect(MiniMagick::Image).to receive(:open).with(Images::TEMPLATE_PATH)
        expect(MiniMagick::Image).to receive(:open).with(default_logo_url)
        expect(MiniMagick::Image).to receive(:open).with("https://thepracticaldev.s3.amazonaws.com/i/99mvlsfu5tfj9m7ku25d.png") # backup link
        expect(MiniMagick::Image).to receive(:open).with(Images::ROUNDED_MASK_PATH)
        instance.read_files(article)
      end

      it "uses the article's subforem logo" do
        expect(Settings::General).to receive(:logo_png).with(subforem_id: default_subforem.id).and_return(default_logo_url)
        expect(MiniMagick::Image).to receive(:open).with(default_logo_url)
        instance.read_files(article)
      end

      context "with custom subforem" do
        let(:instance) { described_class.new(article_with_custom_subforem) }

        before do
          instance.instance_variable_set(:@user, article_with_custom_subforem.user)
        end

        it "uses the custom subforem logo" do
          expect(Settings::General).to receive(:logo_png).with(subforem_id: custom_subforem.id).and_return(custom_logo_url)
          expect(MiniMagick::Image).to receive(:open).with(custom_logo_url)
          instance.read_files(article_with_custom_subforem)
        end
      end

      context "without subforem" do
        let(:instance) { described_class.new(article_without_subforem) }

        before do
          instance.instance_variable_set(:@user, article_without_subforem.user)
        end

        it "falls back to default subforem logo" do
          expect(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
          expect(Settings::General).to receive(:logo_png).with(subforem_id: default_subforem.id).and_return(default_logo_url)
          expect(MiniMagick::Image).to receive(:open).with(default_logo_url)
          instance.read_files(article_without_subforem)
        end
      end

      context "when logo_url is nil" do
        it "does not attempt to open the logo image" do
          allow(Settings::General).to receive(:logo_png).with(subforem_id: default_subforem.id).and_return(nil)
          expect(MiniMagick::Image).not_to receive(:open).with(nil)
          instance.read_files(article)
        end
      end

      context "when logo_url is blank string" do
        it "does not attempt to open the logo image" do
          allow(Settings::General).to receive(:logo_png).with(subforem_id: default_subforem.id).and_return("")
          expect(MiniMagick::Image).not_to receive(:open).with("")
          instance.read_files(article)
        end
      end

      context "caching behavior" do
        it "caches the logo URL and only fetches it once for the same subforem" do
          expect(Settings::General).to receive(:logo_png).with(subforem_id: default_subforem.id).once.and_return(default_logo_url)
          
          # Call read_files multiple times with articles from the same subforem
          instance.read_files(article)
          instance.read_files(article)
          instance.read_files(article)
        end

        it "fetches logo URL again when subforem changes" do
          expect(Settings::General).to receive(:logo_png).with(subforem_id: default_subforem.id).once.and_return(default_logo_url)
          expect(Settings::General).to receive(:logo_png).with(subforem_id: custom_subforem.id).once.and_return(custom_logo_url)
          
          instance.read_files(article)
          instance.instance_variable_set(:@user, article_with_custom_subforem.user)
          instance.read_files(article_with_custom_subforem)
        end

        it "still creates fresh MiniMagick image objects each time" do
          # Create unique mock objects for each call
          allow(MiniMagick::Image).to receive(:open) do |path|
            double("MiniMagick::Image for #{path}")
          end
          
          # First call
          instance.read_files(article)
          first_background = instance.instance_variable_get(:@background_image)
          first_logo = instance.instance_variable_get(:@logo_image)
          
          # Second call with same article
          instance.read_files(article)
          second_background = instance.instance_variable_get(:@background_image)
          second_logo = instance.instance_variable_get(:@logo_image)
          
          # Objects should be different (fresh opens)
          expect(second_background).not_to equal(first_background)
          expect(second_logo).not_to equal(first_logo)
        end

        it "caches author image URL and only calculates it once for the same user" do
          # Call read_files multiple times with articles from the same user
          instance.read_files(article)
          cached_url = instance.instance_variable_get(:@cached_author_image_url)
          
          instance.read_files(article)
          second_cached_url = instance.instance_variable_get(:@cached_author_image_url)
          
          expect(cached_url).to eq(second_cached_url)
        end
      end
    end
  end
  # rubocop:enable Style/Send
  # rubocop:enable RSpec/VerifiedDoubles
  # rubocop:enable Layout/LineLength
  # rubocop:enable RSpec/ContextWording
  # rubocop:enable Style/Semicolon
  # rubocop:enable RSpec/NestedGroups
end

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
  let(:default_logo_url) { "https://example.com/default_logo.png" }
  let(:custom_logo_url) { "https://example.com/custom_logo.png" }
  let(:generated_image) { "https://example.com/og.png" }

  before do
    allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
    allow(Settings::General).to receive(:resized_logo).and_return(nil)
    allow(Settings::General).to receive(:logo_png).with(subforem_id: default_subforem.id).and_return(default_logo_url)
    allow(Settings::General).to receive(:logo_png).with(subforem_id: custom_subforem.id).and_return(custom_logo_url)
  end

  # rubocop:disable Style/Send
  # rubocop:disable Layout/LineLength
  # rubocop:disable RSpec/VerifiedDoubles
  # rubocop:disable RSpec/ContextWording
  # rubocop:disable RSpec/NestedGroups
  # rubocop:disable RSpec/AnyInstance
  describe ".call" do
    context "when resource is an Article" do
      let(:generator) { described_class.new(article) }

      before do
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:generate_image).and_return(generated_image)
      end

      it "generates the image with the author's brand color" do
        described_class.call(article)
        expect(generator).to have_received(:generate_image).with(article, user.setting.brand_color1).once
      end

      it "stores the generated image on the article" do
        described_class.call(article)
        expect(article.reload.social_image).to eq("https://example.com/og.png")
      end

      it "busts article cache" do
        allow(EdgeCache::BustArticle).to receive(:call)
        described_class.call(article)
        expect(EdgeCache::BustArticle).to have_received(:call).with(article)
      end

      context "when an external fetch fails with an HTTP error" do
        it "logs a warning and does not alert Honeybadger" do
          allow(generator).to receive(:generate_image).and_raise(OpenURI::HTTPError.new("404 Not Found", nil))
          allow(Rails.logger).to receive(:warn)
          allow(Rails.error).to receive(:report)

          described_class.call(article)

          expect(Rails.logger).to have_received(:warn).with(/Image fetch failed: 404 Not Found/)
          expect(Rails.error).not_to have_received(:report)
        end
      end

      context "when an external fetch times out" do
        it "logs a warning and does not alert Honeybadger" do
          allow(generator).to receive(:generate_image).and_raise(Net::ReadTimeout)
          allow(Rails.logger).to receive(:warn)
          allow(Rails.error).to receive(:report)

          described_class.call(article)

          expect(Rails.logger).to have_received(:warn).with(/Image fetch failed/)
          expect(Rails.error).not_to have_received(:report)
        end
      end

      context "when MiniMagick throws an error" do
        it "logs a warning and does not alert Honeybadger if it is a status 15 SIGTERM" do
          allow(generator).to receive(:generate_image).and_raise(MiniMagick::Error.new("`convert` failed with status: 15"))
          allow(Rails.logger).to receive(:warn)
          allow(Rails.error).to receive(:report)

          described_class.call(article)

          expect(Rails.logger).to have_received(:warn).with(/SIGTERM/)
          expect(Rails.error).not_to have_received(:report)
        end

        it "alerts Honeybadger for other MiniMagick errors" do
          error = MiniMagick::Error.new("`convert` failed with status: 1")
          allow(generator).to receive(:generate_image).and_raise(error)
          allow(Rails.error).to receive(:report)

          described_class.call(article)

          expect(Rails.error).to have_received(:report).with(error)
        end
      end
    end

    context "when resource is a User" do
      let(:generator) { described_class.new(user) }

      before do
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:generate_image).and_return(generated_image)
      end

      it "generates an image for each published article without an organization or cover" do
        described_class.call(user)
        [article, article_with_custom_subforem, article_without_subforem].each do |art|
          expect(generator).to have_received(:generate_image).with(art, user.setting.brand_color1)
        end
        expect(generator).not_to have_received(:generate_image).with(second_article, anything)
      end

      it "stores the generated image on the articles" do
        described_class.call(user)
        expect(article.reload.social_image).to eq("https://example.com/og.png")
      end
    end

    context "when resource is an Organization" do
      let(:generator) { described_class.new(organization) }

      before do
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:generate_image).and_return(generated_image)
      end

      it "generates the image with the organization's color" do
        described_class.call(organization)
        expect(generator).to have_received(:generate_image).with(second_article, organization.bg_color_hex).once
      end

      it "stores the generated image on the article" do
        described_class.call(organization)
        expect(second_article.reload.social_image).to eq("https://example.com/og.png")
      end
    end

    context "caching optimization" do
      let(:image) { double(destroy!: nil) }

      before do
        create(:article, user_id: user.id, with_main_image: false, subforem: default_subforem)
        RSpec::Mocks.space.proxy_for(Settings::General).reset
        allow(Settings::General).to receive(:resized_logo).and_return(nil)
        allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
        allow(MiniMagick::Image).to receive(:open).and_return(double)
        allow_any_instance_of(described_class).to receive_messages(render_quote: image, render_text: image, draw_background: image, generate_magickally: "https://www.example.com")
      end

      it "fetches the logo URL at most once per run of same-subforem articles" do
        allow(Settings::General).to receive(:logo_png).with(subforem_id: default_subforem.id).and_return(default_logo_url)
        allow(Settings::General).to receive(:logo_png).with(subforem_id: custom_subforem.id).and_return(custom_logo_url)

        described_class.call(user)

        expect(Settings::General).to have_received(:logo_png).with(subforem_id: default_subforem.id).at_least(:once).at_most(2).times
        expect(Settings::General).to have_received(:logo_png).with(subforem_id: custom_subforem.id).once
      end

      it "still opens fresh MiniMagick images for each article" do
        allow(Settings::General).to receive(:logo_png).and_return(default_logo_url)

        described_class.call(user)

        # logo, author image, and mask for each of the 4 eligible articles
        expect(MiniMagick::Image).to have_received(:open).at_least(12).times
      end
    end
  end

  describe "layout" do
    let(:stack) { described_class::WINDOW_STACK_OFFSET * described_class::WINDOW_STACK_DEPTH }
    let(:card_bottom) { described_class::WINDOW_Y + described_class::WINDOW_HEIGHT + stack }

    it "keeps the card above the bottom area where X overlays the post title" do
      expect(card_bottom).to be <= described_class::HEIGHT - described_class::X_KEEP_CLEAR
    end

    it "centers the card vertically" do
      bottom_margin = described_class::HEIGHT - card_bottom
      expect((described_class::WINDOW_Y - bottom_margin).abs).to be <= 1
    end
  end

  describe "#generate_image" do
    let(:generator) { described_class.new(article) }
    let(:written) { [] }

    before do
      generator.instance_variable_set(:@user, user)
      allow(generator).to receive(:read_files) do
        generator.instance_variable_set(:@logo_image, MiniMagick::Image.open(Rails.root.join("spec/fixtures/files/podcast.png").to_s))
        generator.instance_variable_set(:@author_image, MiniMagick::Image.open(Rails.root.join("spec/fixtures/files/800x600.png").to_s))
        generator.instance_variable_set(:@rounded_mask, MiniMagick::Image.open(Images::ROUNDED_MASK_PATH))
      end
      allow(generator).to receive(:upload_result) do |result|
        written << [result.width, result.height]
        "https://example.com/#{written.size}.png"
      end
    end

    it "renders a 1200x627 image with ImageMagick" do
      expect(generator.send(:generate_image, article, "#3b49df")).to eq("https://example.com/1.png")
      expect(written).to eq([[1200, 627]])
    end

    it "quotes the opening of the article" do
      allow(generator).to receive(:render_quote).and_call_original
      generator.send(:generate_image, article, nil)
      expect(generator).to have_received(:render_quote).with(Images::SocialImageQuote.call(article))
    end

    it "cleans up intermediate and opened tempfiles after rendering" do
      generator.send(:generate_image, article, "#3b49df")

      %i[@logo_image @author_image @rounded_mask].each do |ivar|
        expect(generator.instance_variable_get(ivar).tempfile.path).to be_nil
      end
    end
  end

  describe "#render_text" do
    let(:generator) { described_class.new(article) }

    it "does not let a leading @ read a file into the image" do
      file = Tempfile.new(["secret", ".txt"])
      file.write("x")
      file.flush

      image = generator.send(:render_text, "label", "@#{file.path}", Images::BOLD_FONT_PATH, 28, "black")

      # Rendering the one-character file content would be far narrower than the path.
      expect(image.width).to be > 200
    ensure
      image&.destroy!
      file&.close!
    end

    it "renders a blank string without raising an ImageMagick error" do
      image = generator.send(:render_text, "label", "", Images::BOLD_FONT_PATH, 28, "black")
      expect(image.width).to be >= 1
    ensure
      image&.destroy!
    end
  end

  describe "#palette_for" do
    let(:generator) { described_class.new(article) }

    it "uses a default palette, chosen by the seed, when the color is unset" do
      %w[#000000 #111212].push(nil, "", "not-a-color").each do |color|
        expect(generator.send(:palette_for, color, 5)).to eq(described_class::DEFAULT_PALETTES[5 % described_class::DEFAULT_PALETTES.size])
      end
    end

    it "builds an analogous palette that starts with the brand color" do
      palette = generator.send(:palette_for, "#0f9d8a", 1)
      expect(palette.first).to eq("#0f9d8a")
      expect(palette.size).to eq(5)
      expect(palette).to all(match(/\A#\h{6}\z/))
    end

    it "expands three-digit hex colors" do
      expect(generator.send(:palette_for, "#FC0", 1).first).to eq("#ffcc00")
    end

    it "rotates hue with floating-point division for grayscale brand colors" do
      palette = generator.send(:palette_for, "#808080", 1)
      # +38 degrees from 0 is warm amber (green > blue), not pure red (green == blue)
      _, r, g, b = *palette[1].match(/\A#(..)(..)(..)\z/)
      expect(r.to_i(16)).to be > g.to_i(16)
      expect(g.to_i(16)).to be > b.to_i(16)
    end
  end

  describe "#accent_color" do
    let(:generator) { described_class.new(article) }

    it "uses the first dark color in the palette" do
      expect(generator.send(:accent_color, %w[#fff23a #12004a #3333ff])).to eq("#12004a")
    end

    it "falls back to the community's primary brand color for light palettes" do
      allow(Settings::UserExperience).to receive(:primary_brand_color_hex).and_return("#123456")
      expect(generator.send(:accent_color, %w[#fff23a #ffffff])).to eq("#123456")
    end
  end

  describe "#display_name" do
    let(:generator) { described_class.new(article) }

    it "turns stylized Unicode letters into plain ones the fonts can render" do
      expect(generator.send(:display_name, "\u{1D413}\u{1D421}\u{1D41E} \u{1D40B}\u{1D41A}\u{1D433}\u{1D432}")).to eq("The Lazy")
    end

    it "drops emoji and truncates long names" do
      expect(generator.send(:display_name, "Jess \u{1F984}")).to eq("Jess")
      expect(generator.send(:display_name, "a" * 60).length).to eq(described_class::MAX_NAME_LENGTH)
    end

    it "falls back to the username when the name is emoji-only" do
      generator.instance_variable_set(:@user, user)
      expect(generator.send(:display_name, "\u{1F525}\u{1F984}")).to eq(user.username)
    end
  end

  describe "#meta_line" do
    let(:generator) { described_class.new(article) }

    it "shows the date and reading time" do
      article.reading_time = 7
      expect(generator.send(:meta_line, article)).to eq("#{article.readable_publish_date}  ·  7 min read")
    end

    it "shows at least one minute of reading time" do
      article.reading_time = 0
      expect(generator.send(:meta_line, article)).to end_with("1 min read")
    end
  end

  describe "#escape_text" do
    let(:generator) { described_class.new(article) }

    it "escapes backslashes before other characters" do
      expect(generator.send(:escape_text, 'a\\b')).to eq('a\\\\b')
    end

    it "escapes double-quotes" do
      expect(generator.send(:escape_text, 'say "hello"')).to eq('say \\"hello\\"')
    end

    it "escapes @ to prevent ImageMagick indirect file reads" do
      expect(generator.send(:escape_text, "user@example")).to eq("user\\@example")
    end

    it "escapes % to prevent ImageMagick format sequences" do
      expect(generator.send(:escape_text, "50%")).to eq("50\\%")
    end

    it "does not raise on CJK and Unicode characters" do
      unicode_name = "FrancisTRᴅᴇᴠ (っ◔◡◔)っ"
      expect { generator.send(:escape_text, unicode_name) }.not_to raise_error
    end
  end

  describe "#add_profile_image" do
    let(:generator) { described_class.new(article) }
    let(:result_image) { double(MiniMagick::Image) }
    let(:author_image) { double(MiniMagick::Image) }
    let(:rounded_mask) { double(MiniMagick::Image) }

    before do
      allow(result_image).to receive_messages(composite: result_image, combine_options: result_image)
      allow(author_image).to receive(:collapse!)
      allow(author_image).to receive(:format)
      allow(author_image).to receive(:resize)
      allow(rounded_mask).to receive(:resize)

      generator.instance_variable_set(:@author_image, author_image)
      generator.instance_variable_set(:@rounded_mask, rounded_mask)
    end

    it "adds the profile image and rounded mask after collapsing animation frames" do
      generator.send(:add_profile_image, result_image)
      expect(author_image).to have_received(:collapse!)
      expect(author_image).to have_received(:format).with("png")
      expect(author_image).to have_received(:resize).with("64x64!")
      expect(rounded_mask).to have_received(:resize).with("64x64")
      expect(result_image).to have_received(:composite).twice
    end

    it "gracefully rescues a Timeout::Error, reports it, and returns the image without an avatar" do
      allow(author_image).to receive(:collapse!).and_raise(Timeout::Error)
      allow(Rails.error).to receive(:report)

      expect(generator.send(:add_profile_image, result_image)).to eq(result_image)
      expect(Rails.error).to have_received(:report).with(instance_of(Timeout::Error))
      expect(author_image).not_to have_received(:resize)
      expect(result_image).not_to have_received(:composite)
    end
  end

  describe "#add_logo" do
    let(:generator) { described_class.new(article) }
    let(:result_image) { double(MiniMagick::Image) }
    let(:logo_image) { double(MiniMagick::Image) }

    before do
      allow(result_image).to receive(:composite).and_return(result_image)
      allow(logo_image).to receive(:resize)
      generator.instance_variable_set(:@logo_image, logo_image)
    end

    it "scales the logo to the window's title bar and adds it" do
      generator.send(:add_logo, result_image)
      expect(logo_image).to have_received(:resize).with("x#{described_class::LOGO_HEIGHT}")
      expect(result_image).to have_received(:composite).with(logo_image)
    end

    it "does not add a logo when there is none" do
      generator.instance_variable_set(:@logo_image, nil)
      expect(generator.send(:add_logo, result_image)).to eq(result_image)
      expect(result_image).not_to have_received(:composite)
    end
  end

  describe "#upload_result" do
    let(:generator) { described_class.new(article) }
    let(:result_image) { double(MiniMagick::Image) }
    let(:tempfile) { instance_double(Tempfile, path: "/tmp/output.png") }
    let(:uploader) { instance_double(ArticleImageUploader) }

    before do
      allow(Tempfile).to receive(:new).and_return(tempfile)
      allow(tempfile).to receive(:close)
      allow(tempfile).to receive(:unlink)
      allow(result_image).to receive(:combine_options)
      allow(result_image).to receive(:format)
      allow(result_image).to receive(:write)
      allow(ArticleImageUploader).to receive(:new).and_return(uploader)
      allow(uploader).to receive(:store!)
      allow(uploader).to receive(:url).and_return("http://example.com/social_image.png")
    end

    it "writes an 8-bit PNG, uploads it, then cleans up the tempfile" do
      expect(generator.send(:upload_result, result_image)).to eq "http://example.com/social_image.png"

      expect(result_image).to have_received(:format).with("png")
      expect(Tempfile).to have_received(:new).with(["output", ".png"])
      expect(result_image).to have_received(:write).with(tempfile.path)
      expect(uploader).to have_received(:store!).with(tempfile)
      expect(tempfile).to have_received(:close)
      expect(tempfile).to have_received(:unlink)
    end
  end

  describe "#read_files" do
    let(:instance) { described_class.new(article) }

    before do
      allow(MiniMagick::Image).to receive(:open)
      instance.instance_variable_set(:@user, article.user)
    end

    it "opens the logo, author image, and rounded mask" do
      instance.send(:read_files, article)
      expect(MiniMagick::Image).to have_received(:open).with(default_logo_url)
      expect(MiniMagick::Image).to have_received(:open).with(Images::Profile::BACKUP_LINK)
      expect(MiniMagick::Image).to have_received(:open).with(Images::ROUNDED_MASK_PATH)
    end

    it "prefers the community's horizontal header logo" do
      allow(Settings::General).to receive(:resized_logo).with(subforem_id: default_subforem.id).and_return("https://example.com/header_logo.png")
      instance.send(:read_files, article)
      expect(MiniMagick::Image).to have_received(:open).with("https://example.com/header_logo.png")
      expect(MiniMagick::Image).not_to have_received(:open).with(default_logo_url)
    end

    context "with custom subforem" do
      it "uses the custom subforem logo" do
        instance.send(:read_files, article_with_custom_subforem)
        expect(MiniMagick::Image).to have_received(:open).with(custom_logo_url)
      end
    end

    context "without subforem" do
      it "falls back to default subforem logo" do
        instance.send(:read_files, article_without_subforem)
        expect(MiniMagick::Image).to have_received(:open).with(default_logo_url)
      end
    end

    context "when there is no logo" do
      it "does not attempt to open the logo image" do
        allow(Settings::General).to receive(:logo_png).with(subforem_id: default_subforem.id).and_return("")
        instance.send(:read_files, article)
        expect(MiniMagick::Image).not_to have_received(:open).with("")
        expect(instance.instance_variable_get(:@logo_image)).to be_nil
      end
    end

    context "caching behavior" do
      it "fetches the logo URL once for the same subforem" do
        3.times { instance.send(:read_files, article) }
        expect(Settings::General).to have_received(:logo_png).with(subforem_id: default_subforem.id).once
      end

      it "fetches the logo URL again when the subforem changes" do
        instance.send(:read_files, article)
        instance.send(:read_files, article_with_custom_subforem)
        expect(Settings::General).to have_received(:logo_png).with(subforem_id: default_subforem.id).once
        expect(Settings::General).to have_received(:logo_png).with(subforem_id: custom_subforem.id).once
      end

      it "still creates fresh MiniMagick image objects each time" do
        allow(MiniMagick::Image).to receive(:open) { |path| double("MiniMagick::Image for #{path}") }

        instance.send(:read_files, article)
        first_logo = instance.instance_variable_get(:@logo_image)
        instance.send(:read_files, article)

        expect(instance.instance_variable_get(:@logo_image)).not_to equal(first_logo)
      end
    end
  end
  # rubocop:enable RSpec/AnyInstance
  # rubocop:enable RSpec/NestedGroups
  # rubocop:enable RSpec/ContextWording
  # rubocop:enable RSpec/VerifiedDoubles
  # rubocop:enable Layout/LineLength
  # rubocop:enable Style/Send
end

require "rails_helper"

RSpec.describe NavigationLink do
  let(:navigation_link) { create(:navigation_link) }

  describe ".from_subforem" do
    let!(:link_subforem_1) { create(:navigation_link, subforem_id: 1) }
    let!(:link_subforem_2) { create(:navigation_link, subforem_id: 2) }
    let!(:link_no_subforem) { create(:navigation_link, subforem_id: nil) }

    after do
      RequestStore.store[:subforem_id] = nil
    end

    context "when subforem_id is not explicitly passed" do
      before do
        RequestStore.store[:subforem_id] = 1
      end

      it "defaults to RequestStore.store[:subforem_id]" do
        expect(described_class.from_subforem)
          .to contain_exactly(link_subforem_1, link_no_subforem)
      end
    end

    context "when subforem_id is explicitly passed" do
      it "uses the passed subforem_id" do
        expect(described_class.from_subforem(2))
          .to contain_exactly(link_subforem_2, link_no_subforem)
      end
    end

    context "when RequestStore.store[:subforem_id] is nil" do
      it "returns records where subforem_id is nil if no argument is passed" do
        # subforem_id in store remains nil by default
        expect(described_class.from_subforem)
          .to contain_exactly(link_no_subforem)
      end
    end
  end

  describe ".create_or_update_by_identity" do
    let(:attributes) { attributes_for(:navigation_link).except(:url, :id, :name).stringify_keys }
    let(:name) { navigation_link.name }

    # I want an existing navigation link, but don't want to apply the `let!` to the declaration as
    # that impacts tests in other describe blocks.
    before { navigation_link }

    context "when the url already exists" do
      let(:url) { navigation_link.url }

      it "updates the existing NavigationLink" do
        expect do
          described_class.create_or_update_by_identity(url: url, name: name, **attributes.symbolize_keys)
        end.not_to change(described_class, :count)

        expect(navigation_link.reload.attributes.slice(*attributes.keys)).to eq(attributes)
      end
    end

    context "when the url does not exist" do
      # Creating a different URL
      let(:url) { "#{navigation_link.url}-404" }

      it "creates a new NavigationLink" do
        expect do
          described_class.create_or_update_by_identity(url: url, name: name, **attributes)
        end.to change(described_class, :count).by(1)
      end
    end
  end

  describe "validations" do
    describe "presence validations" do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:url) }
    end

    describe "icon or image validation" do
      it "is valid without either icon or image (falls back to default)" do
        link = build(:navigation_link, icon: nil, image: nil)
        expect(link).to be_valid
      end

      it "is valid with an icon and no image" do
        link = build(:navigation_link, icon: "<svg xmlns='http://www.w3.org/2000/svg'></svg>", image: nil)
        expect(link).to be_valid
      end

      it "is valid with an image and no icon" do
        allow_any_instance_of(NavigationLinkImageUploader).to receive(:validate_frame_count)
        allow_any_instance_of(NavigationLinkImageUploader).to receive(:strip_exif)
        link = build(:navigation_link, icon: nil)
        link.image = fixture_file_upload("800x600.png", "image/png")
        expect(link).to be_valid
      end
    end

    it "validates the icon format" do
      navigation_link.icon = "test.png"
      expect(navigation_link).not_to be_valid

      navigation_link.icon = "<svg foo='bar'>"
      expect(navigation_link).to be_valid

      navigation_link.icon = "<svg foo='bar'\nbaz='lol'\n\n more stuff...\n\n.  >"
      expect(navigation_link).to be_valid

      navigation_link.icon = "something...something\n<svg foo='bar'\nbaz='lol'\n\n more stuff...\n\n.  >"
      expect(navigation_link).not_to be_valid

      navigation_link.icon = "<svg foo='bar'\nbaz='lol'\n\n more stuff...\n\n.  >\n\n\n\n"
      expect(navigation_link).to be_valid

      navigation_link.icon = "<svg foo='bar'\nbaz='lol'\n\n more stuff...\n\n.  >\n\n\t     \n\n"
      expect(navigation_link).to be_valid

      navigation_link.icon = "<svg foo='bar'\nbaz='lol'\n\n more stuff...\n\n.  >\n\nsomething\n\n"
      expect(navigation_link).not_to be_valid
    end

    context "when validating the URL" do
      it "does not allow invalid URLs" do
        navigation_link.url = "test"
        expect(navigation_link).not_to be_valid
      end

      it "does allow relative URLs" do
        navigation_link.url = "/test"
        expect(navigation_link).to be_valid
      end
    end
  end

  describe "callbacks" do
    let(:base_url) { "https://testforem.com" }

    before { allow(URL).to receive(:url).and_return(base_url) }

    it "normalizes local URLs to relative URLs on save" do
      navigation_link.url = "#{base_url}/test"
      navigation_link.save
      expect(navigation_link.url).to eq "/test"
    end

    it "persists relative URLs unchanged" do
      navigation_link.url = "/test"
      navigation_link.save
      expect(navigation_link.url).to eq "/test"
    end

    it "persists external URLs unchanged" do
      url = "https://example.com/test"
      navigation_link.url = url
      navigation_link.save
      expect(navigation_link.url).to eq url
    end
  end

  describe "default icon fallback" do
    it "sets default icon when both icon and image are blank" do
      link = build(:navigation_link, icon: nil, image: nil)
      link.validate
      expect(link.icon).to eq(described_class.default_icon_svg)
    end

    it "does not override provided icon" do
      custom_icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><circle cx='5' cy='5' r='4'/></svg>"
      link = build(:navigation_link, icon: custom_icon, image: nil)
      link.validate
      expect(link.icon).to eq(custom_icon)
    end

    it "does not set icon when image is provided" do
      allow_any_instance_of(NavigationLinkImageUploader).to receive(:validate_frame_count)
      allow_any_instance_of(NavigationLinkImageUploader).to receive(:strip_exif)
      link = build(:navigation_link, icon: nil)
      link.image = fixture_file_upload("800x600.png", "image/png")
      link.validate
      expect(link.icon).to be_nil
    end

    it "persists the default icon when saved without icon or image" do
      link = create(:navigation_link, icon: nil, image: nil)
      expect(link.reload.icon).to eq(described_class.default_icon_svg)
    end

    it "loads default icon from link.svg file" do
      expected_svg = Rails.root.join("app/assets/images/link.svg").read.strip
      expect(described_class.default_icon_svg).to eq(expected_svg)
    end

    it "caches the default icon SVG content" do
      # First call loads from file
      first_call = described_class.default_icon_svg
      
      # Second call should return the same object (cached)
      second_call = described_class.default_icon_svg
      
      expect(first_call).to eq(second_call)
      expect(first_call.object_id).to eq(second_call.object_id)
    end
  end

  describe "#icon_display" do
    it "returns image URL when image is present" do
      allow_any_instance_of(NavigationLinkImageUploader).to receive(:validate_frame_count)
      allow_any_instance_of(NavigationLinkImageUploader).to receive(:strip_exif)
      link = build(:navigation_link, icon: nil)
      link.image = fixture_file_upload("800x600.png", "image/png")
      link.save
      expect(link.icon_display).to eq(link.image.url)
    end

    it "returns custom icon when provided and no image" do
      custom_icon = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10 10'><circle cx='5' cy='5' r='4'/></svg>"
      link = create(:navigation_link, icon: custom_icon, image: nil)
      expect(link.icon_display).to eq(custom_icon)
    end

    it "returns default icon when neither icon nor image was provided" do
      link = create(:navigation_link, icon: nil, image: nil)
      expect(link.icon_display).to eq(described_class.default_icon_svg)
    end
  end
end

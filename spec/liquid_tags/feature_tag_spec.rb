require "rails_helper"

RSpec.describe FeatureTag, type: :liquid_tag do
  before do
    Liquid::Template.register_tag("features", FeaturesTag)
    Liquid::Template.register_tag("feature", FeatureTag)
  end

  def render_feature(options)
    Liquid::Template.parse("{% features %}{% feature #{options} %}Body{% endfeature %}{% endfeatures %}").render
  end

  describe "the curated icon list" do
    it "is frozen and non-empty" do
      expect(described_class::ICONS).to be_frozen
      expect(described_class::ICONS).not_to be_empty
    end

    it "contains only unique, slug-formatted names" do
      expect(described_class::ICONS.uniq).to eq(described_class::ICONS)
      expect(described_class::ICONS).to all(match(described_class::ICON_NAME_REGEXP))
    end

    it "maps every supported name to an existing root-level SVG asset" do
      missing = described_class::ICONS.reject do |icon|
        Rails.root.join("app/assets/images/#{icon}.svg").exist?
      end

      expect(missing).to be_empty, "Missing SVG assets for: #{missing.join(', ')}"
    end

    it "resolves every legacy alias to a supported icon" do
      expect(described_class::LEGACY_ICON_ALIASES.values).to all(be_in(described_class::ICONS))
    end
  end

  describe "supported icons" do
    it "renders the matching crayons icon" do
      result = render_feature('title="Fast" icon="lightning"')

      expect(result).to include("ltag-feature__icon")
      expect(result).to include("crayons-icon")
      expect(result).to match(/<svg/)
    end

    it "renders every curated icon without error" do
      expect do
        described_class::ICONS.each { |icon| render_feature(%(title="T" icon="#{icon}")) }
      end.not_to raise_error
    end
  end

  describe "unsupported icons" do
    it "raises a descriptive error naming the offending icon" do
      expect do
        render_feature('title="Broken" icon="not-a-real-icon"')
      end.to raise_error(StandardError, /Invalid icon 'not-a-real-icon'/)
    end

    it "lists the supported icons in the error message" do
      expect do
        render_feature('title="Broken" icon="not-a-real-icon"')
      end.to raise_error(StandardError, /#{Regexp.escape(described_class::ICONS.join(', '))}/)
    end

    it "points authors at the emoji escape hatch" do
      expect do
        render_feature('title="Broken" icon="totally-unknown"')
      end.to raise_error(StandardError, /Use an emoji or one of/)
    end

    it "raises for a name that exists as an asset but is not curated" do
      expect(Rails.root.join("app/assets/images/twitter.svg")).to exist
      expect(described_class::ICONS).not_to include("twitter")

      expect { render_feature('title="Off list" icon="twitter"') }
        .to raise_error(StandardError, /Invalid icon 'twitter'/)
    end

    it "validates the title before the icon" do
      expect { render_feature('icon="not-a-real-icon"') }
        .to raise_error(StandardError, /requires a title/)
    end
  end

  describe "features without an icon" do
    it "renders the card and omits the icon container" do
      result = render_feature('title="No Icon"')

      expect(result).to include("ltag-feature__title")
      expect(result).to include("No Icon")
      expect(result).not_to include("ltag-feature__icon")
    end
  end

  describe "backward compatibility" do
    it "still accepts emoji icons verbatim" do
      result = render_feature('title="Launch" icon="🚀"')

      expect(result).to include("ltag-feature__icon")
      expect(result).to include("🚀")
    end

    it "accepts the previously documented rocket icon" do
      expect { render_feature('title="Fast" icon="rocket"') }.not_to raise_error
    end

    it "renders the rocket alias as a real icon instead of the heart fallback" do
      result = render_feature('title="Fast" icon="rocket"')

      expect(result).to include("ltag-feature__icon")
      expect(result).to match(/<svg/)
    end
  end

  describe "article integration" do
    def article_with_icon(icon)
      body = <<~MARKDOWN
        ---
        title: Feature tag icons
        published: false
        tags: javascript
        ---

        {% features %}
        {% feature title="Fast" icon="#{icon}" %}Speed{% endfeature %}
        {% endfeatures %}
      MARKDOWN

      build(:article, body_markdown: body)
    end

    it "is valid when a supported icon is used" do
      article = article_with_icon("lightning")

      expect(article).to be_valid
      expect(article.processed_html).to include("ltag-feature__icon")
    end

    it "surfaces an authoring error when an unsupported icon is used" do
      article = article_with_icon("rocketship")

      expect(article).not_to be_valid
      expect(article.errors[:base].first).to match(/Invalid icon 'rocketship'/)
    end

    it "keeps previously published rocket markup saveable" do
      expect(article_with_icon("rocket")).to be_valid
    end
  end

  describe "editor documentation" do
    let(:help) { Rails.root.join("app/views/pages/_editor_liquid_help.en.html.erb").read }

    it "documents the supported icons from the single source of truth" do
      expect(help).to include("FeatureTag::ICONS")
    end

    it "only demonstrates icons that actually render" do
      documented = help.scan(/\{%\s*feature\b[^%]*icon="([a-z0-9-]+)"/).flatten

      expect(documented).not_to be_empty
      expect(documented).to all(be_in(described_class::ICONS))
    end
  end
end

require "rails_helper"

RSpec.describe "Features and Feature liquid tags", type: :liquid_tag do
  before do
    Liquid::Template.register_tag("features", FeaturesTag)
    Liquid::Template.register_tag("feature", FeatureTag)
  end

  def parse(template)
    Liquid::Template.parse(template)
  end

  describe "features grid" do
    it "renders a features grid with feature cards" do
      result = parse('{% features %}{% feature title="Fast" %}Blazing speed{% endfeature %}{% feature title="Secure" %}Enterprise grade{% endfeature %}{% endfeatures %}').render
      expect(result).to include('class="ltag-features"')
      expect(result).to include('class="ltag-feature"')
      expect(result).to include("Fast")
      expect(result).to include("Blazing speed")
      expect(result).to include("Secure")
      expect(result).to include("Enterprise grade")
    end

    it "renders a single feature" do
      result = parse('{% features %}{% feature title="Only One" %}Content{% endfeature %}{% endfeatures %}').render
      expect(result.scan('class="ltag-feature"').size).to eq(1)
    end

    it "raises error if features tag receives arguments" do
      expect do
        parse('{% features cols=3 %}{% endfeatures %}')
      end.to raise_error(StandardError, /does not accept any arguments/)
    end
  end

  describe "feature tag" do
    it "renders with title only" do
      result = parse('{% features %}{% feature title="Title" %}Body{% endfeature %}{% endfeatures %}').render
      expect(result).to include("ltag-feature__title")
      expect(result).to include("Title")
      expect(result).not_to include("ltag-feature__icon")
    end

    it "renders with icon and title" do
      result = parse('{% features %}{% feature icon="rocket-line" title="Launch" %}Go{% endfeature %}{% endfeatures %}').render
      expect(result).to include("ltag-feature__icon")
      expect(result).to include("ri-rocket-line")
      expect(result).to include("Launch")
    end

    it "preserves HTML content in body" do
      result = parse('{% features %}{% feature title="Test" %}<strong>Bold</strong>{% endfeature %}{% endfeatures %}').render
      expect(result).to include("<strong>Bold</strong>")
    end

    it "raises error when title is missing" do
      expect do
        parse('{% features %}{% feature icon="star-line" %}No title{% endfeature %}{% endfeatures %}')
      end.to raise_error(StandardError, /requires a title/)
    end
  end
end

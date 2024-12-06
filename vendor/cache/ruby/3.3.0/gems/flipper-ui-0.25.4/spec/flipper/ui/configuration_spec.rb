RSpec.describe Flipper::UI::Configuration do
  let(:configuration) { described_class.new }

  describe "#delete" do
    it "has default text" do
      expect(configuration.delete.title).to eq("Danger Zone")
      expect(configuration.delete.description).to eq("Deleting a feature removes it from the list of features and disables it for everyone.")
    end
  end

  describe "#banner_text" do
    it "has no default" do
      expect(configuration.banner_text).to eq(nil)
    end

    it "can be updated" do
      configuration.banner_text = 'Production Environment'
      expect(configuration.banner_text).to eq('Production Environment')
    end
  end

  describe "#banner_class" do
    it "has default color" do
      expect(configuration.banner_class).to eq('danger')
    end

    it "can be updated" do
      configuration.banner_class = 'info'
      expect(configuration.banner_class).to eq('info')
    end

    it "raises if set to invalid value" do
      expect { configuration.banner_class = :invalid_class }
        .to raise_error(Flipper::InvalidConfigurationValue)
    end
  end

  describe "#application_breadcrumb_href" do
    it "has default value" do
      expect(configuration.application_breadcrumb_href).to eq(nil)
    end

    it "can be updated" do
      configuration.application_breadcrumb_href = 'http://www.myapp.com'
      expect(configuration.application_breadcrumb_href).to eq('http://www.myapp.com')
    end
  end

  describe "#feature_creation_enabled" do
    it "has default value" do
      expect(configuration.feature_creation_enabled).to eq(true)
    end

    it "can be updated" do
      configuration.feature_creation_enabled = false
      expect(configuration.feature_creation_enabled).to eq(false)
    end
  end

  describe "#cloud_recommendation" do
    it "has default value" do
      expect(configuration.cloud_recommendation).to eq(true)
    end

    it "can be updated" do
      configuration.cloud_recommendation = false
      expect(configuration.cloud_recommendation).to eq(false)
    end
  end

  describe "#feature_removal_enabled" do
    it "has default value" do
      expect(configuration.feature_removal_enabled).to eq(true)
    end

    it "can be updated" do
      configuration.feature_removal_enabled = false
      expect(configuration.feature_removal_enabled).to eq(false)
    end
  end

  describe "#fun" do
    it "has default value" do
      expect(configuration.fun).to eq(true)
    end

    it "can be updated" do
      configuration.fun = false
      expect(configuration.fun).to eq(false)
    end
  end

  describe "#descriptions_source" do
    it "has default value" do
      expect(configuration.descriptions_source.call(%w[foo bar])).to eq({})
    end

    context "descriptions source is provided" do
      it "can be updated" do
        configuration.descriptions_source = lambda do |_keys|
          YAML.load_file(FlipperRoot.join('spec/support/descriptions.yml'))
        end
        keys = %w[some_awesome_feature foo]
        result = configuration.descriptions_source.call(keys)
        expected = {
          "some_awesome_feature" => "Awesome feature description",
        }
        expect(result).to eq(expected)
      end
    end
  end

  describe "#show_feature_description_in_list" do
    it "has default value" do
      expect(configuration.show_feature_description_in_list).to eq(false)
    end

    it "can be updated" do
      configuration.show_feature_description_in_list = true
      expect(configuration.show_feature_description_in_list).to eq(true)
    end
  end

  describe "#show_feature_description_in_list?" do
    subject { configuration.show_feature_description_in_list? }

    context 'when using_descriptions? is false and show_feature_description_in_list is false' do
      it { is_expected.to eq(false) }
    end

    context 'when using_descriptions? is false and show_feature_description_in_list is true' do
      before { configuration.show_feature_description_in_list = true }
      it { is_expected.to eq(false) }
    end

    context 'when using_descriptions? is true and show_feature_description_in_list is false' do
      before { allow(configuration).to receive(:using_descriptions?).and_return(true) }
      it { is_expected.to eq(false) }
    end

    context 'when using_descriptions? is true and show_feature_description_in_list is true' do
      before do
        allow(configuration).to receive(:using_descriptions?).and_return(true)
        configuration.show_feature_description_in_list = true
      end
      it { is_expected.to eq(true) }
    end
  end
end

require "rails_helper"
require "uri"

RSpec.describe GlitchTag, type: :liquid_tag do
  let(:base_uri) { "https://glitch.com/embed/#!/embed/" }

  describe "#id" do
    let(:valid_id) { "BXgGcAUjM39" }
    let(:id_with_quotes) { 'some-id" onload="alert(42)"' }
    let(:id_with_app_option) { "some-id app" }
    let(:id_with_code_option) { "some-id code" }
    let(:id_with_no_files_option) { "some-id no-files" }
    let(:id_with_no_attribution_option) { "some-id no-attribution" }
    let(:id_with_preview_first_option) { "some-id preview-first" }
    let(:id_with_file_option) { "some-id file=script.js" }
    let(:id_with_app_and_code_option) { "some-id app code" }
    let(:id_with_many_options) { "some-id app no-attribution no-files file=script.js" }

    def generate_tag(id)
      Liquid::Template.register_tag("glitch", GlitchTag)
      Liquid::Template.parse("{% glitch #{id} %}")
    end

    it "accepts a valid id" do
      expect { generate_tag(valid_id) }.not_to raise_error
    end

    it "does not accept double quotes" do
      expect { generate_tag(id_with_quotes) }.to raise_error(StandardError)
    end

    it "handles 'app' option" do
      template = generate_tag(id_with_app_option)
      expected = "src=\"#{base_uri}some-id?previewSize=100&amp;path=index.html"
      expect(template.render(nil)).to include(expected)
    end

    it "handles 'code' option" do
      template = generate_tag(id_with_code_option)
      expected = "src=\"#{base_uri}some-id?previewSize=0&amp;path=index.html"
      expect(template.render(nil)).to include(expected)
    end

    it "handles 'no-files' option" do
      template = generate_tag(id_with_no_files_option)
      expected = "src=\"#{base_uri}some-id?sidebarCollapsed=true&amp;path=index.html"
      expect(template.render(nil)).to include(expected)
    end

    it "handles 'preview-first' option" do
      template = generate_tag(id_with_preview_first_option)
      expected = "src=\"#{base_uri}some-id?previewFirst=true&amp;path=index.html"
      expect(template.render(nil)).to include(expected)
    end

    it "handles 'no-attribution' option" do
      template = generate_tag(id_with_no_attribution_option)
      expected = "src=\"#{base_uri}some-id?attributionHidden=true&amp;path=index.html"
      expect(template.render(nil)).to include(expected)
    end

    it "handles 'file' option" do
      template = generate_tag(id_with_file_option)
      expected = "src=\"#{base_uri}some-id?path=script.js"
      expect(template.render(nil)).to include(expected)
    end

    it "handles complex case" do
      template = generate_tag(id_with_many_options)
      expected = "src=\"#{base_uri}some-id?previewSize=100&amp;attributionHidden=true&amp;sidebarCollapsed=true&amp;path=script.js" # rubocop:disable Layout/LineLength
      expect(template.render(nil)).to include(expected)
    end

    it "'app' and 'code' cancel each other" do
      template = generate_tag(id_with_app_and_code_option)
      expected = "src=\"#{base_uri}some-id?path=index.html"
      expect(template.render(nil)).to include(expected)
    end
  end
end

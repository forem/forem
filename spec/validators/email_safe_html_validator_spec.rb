require "rails_helper"

RSpec.describe EmailSafeHtmlValidator do
  let(:test_class) do
    Class.new do
      include ActiveModel::Validations
      attr_accessor :footer

      validates :footer, email_safe_html: true

      def self.name
        "TestModel"
      end
    end
  end

  let(:model) { test_class.new }

  describe "valid HTML" do
    it "allows simple paragraph with inline styles" do
      model.footer = '<p style="color: #333;">Hello World</p>'
      expect(model).to be_valid
    end

    it "allows links with inline styles" do
      model.footer = '<a href="https://example.com" style="color: blue;">Click here</a>'
      expect(model).to be_valid
    end

    it "allows tables with inline styles" do
      model.footer = '<table style="width: 100%;"><tr><td style="padding: 10px;">Cell</td></tr></table>'
      expect(model).to be_valid
    end

    it "allows multiple allowed tags" do
      model.footer = '<div><p><strong>Bold</strong> and <em>italic</em></p></div>'
      expect(model).to be_valid
    end

    it "allows images with safe attributes" do
      model.footer = '<img src="https://example.com/image.png" alt="Logo" width="100" height="50" />'
      expect(model).to be_valid
    end

    it "allows blank/nil values" do
      model.footer = nil
      expect(model).to be_valid

      model.footer = ""
      expect(model).to be_valid
    end
  end

  describe "invalid HTML" do
    it "rejects JavaScript in script tags" do
      model.footer = '<script>alert("XSS")</script>'
      expect(model).not_to be_valid
      expect(model.errors[:footer]).to include(match(/JavaScript or event handlers/))
    end

    it "rejects inline JavaScript" do
      model.footer = '<a href="javascript:alert(1)">Click</a>'
      expect(model).not_to be_valid
      expect(model.errors[:footer]).to include(match(/JavaScript or event handlers/))
    end

    it "rejects event handlers" do
      model.footer = '<div onclick="alert(1)">Click me</div>'
      expect(model).not_to be_valid
      expect(model.errors[:footer]).to include(match(/JavaScript or event handlers/))
    end

    it "rejects external stylesheets" do
      model.footer = '<link rel="stylesheet" href="styles.css">'
      expect(model).not_to be_valid
      expect(model.errors[:footer]).to include(match(/external stylesheets/))
    end

    it "rejects style tags" do
      model.footer = '<style>.class { color: red; }</style>'
      expect(model).not_to be_valid
      expect(model.errors[:footer]).to include(match(/external stylesheets/))
    end

    it "rejects @import in styles" do
      model.footer = '<div style="@import url(evil.css);">Text</div>'
      expect(model).not_to be_valid
      expect(model.errors[:footer]).to include(match(/external stylesheets/))
    end

    it "warns when too much content is stripped" do
      # Create HTML with many unsupported tags that will be stripped
      unsupported_html = '<iframe src="bad"></iframe>' * 50
      model.footer = unsupported_html
      expect(model).not_to be_valid
      expect(model.errors[:footer]).to include(match(/unsupported HTML elements/))
    end
  end

  describe "edge cases" do
    it "handles mixed case script tags" do
      model.footer = '<ScRiPt>alert(1)</ScRiPt>'
      expect(model).not_to be_valid
    end

    it "handles event handlers with various cases" do
      model.footer = '<div OnClick="alert(1)">Click</div>'
      expect(model).not_to be_valid
    end

    it "allows complex but safe HTML" do
      safe_html = <<~HTML
        <div style="background: #f5f5f5; padding: 20px;">
          <h2 style="color: #333;">Newsletter</h2>
          <p style="line-height: 1.5;">
            Visit our <a href="https://example.com" style="color: #0066cc;">website</a>
          </p>
          <table style="width: 100%;">
            <tr>
              <td style="padding: 10px;">
                <img src="https://example.com/logo.png" alt="Logo" width="100" />
              </td>
            </tr>
          </table>
        </div>
      HTML

      model.footer = safe_html
      expect(model).to be_valid
    end
  end
end

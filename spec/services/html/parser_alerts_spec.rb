require "rails_helper"

RSpec.describe Html::Parser, type: :service do
  def transform(html)
    described_class.new(html).transform_markdown_alerts.html
  end

  def rendered(markdown)
    MarkdownProcessor::Parser.new(markdown).finalize
  end

  describe "#transform_markdown_alerts" do
    Html::Parser::ALERT_TYPES.each do |type|
      it "tags a #{type} alert" do
        result = transform("<blockquote><p>[!#{type.upcase}]\nBody</p></blockquote>")

        expect(result).to include(%(data-alert="#{type}"))
        expect(result).to include("Body")
      end
    end

    it "is case insensitive on the token" do
      expect(transform("<blockquote><p>[!tip] Body</p></blockquote>"))
        .to include(%(data-alert="tip"))
    end

    it "removes the token from the visible text" do
      expect(transform("<blockquote><p>[!NOTE] Body</p></blockquote>"))
        .not_to include("[!NOTE]")
    end

    it "adds a translated label" do
      expect(transform("<blockquote><p>[!WARNING] Body</p></blockquote>"))
        .to include(I18n.t("services.html.parser.alerts.warning"))
    end

    it "leaves an ordinary blockquote untouched" do
      html = "<blockquote><p>Just a quote</p></blockquote>"

      expect(transform(html)).not_to include("data-alert")
    end

    it "leaves an unrecognised token as a plain blockquote" do
      html = "<blockquote><p>[!SOMETHING] Body</p></blockquote>"
      result = transform(html)

      expect(result).not_to include("data-alert")
      expect(result).to include("[!SOMETHING]")
    end

    it "only matches the token at the start" do
      html = "<blockquote><p>Body mentioning [!TIP] midway</p></blockquote>"

      expect(transform(html)).not_to include("data-alert")
    end

    it "still tags an alert with no body, matching GitHub" do
      result = transform("<blockquote><p>[!TIP]</p></blockquote>")

      expect(result).to include(%(data-alert="tip"))
      expect(result).to include(I18n.t("services.html.parser.alerts.tip"))
    end
  end

  describe "surviving the markdown pipeline" do
    it "keeps data-alert through the rendered markdown scrubber" do
      result = rendered("> [!TIP]\n> Use the thing.")

      expect(result).to include(%(data-alert="tip"))
      expect(result).to include("Use the thing.")
    end

    it "keeps the body and drops the break left by the token newline" do
      result = rendered("> [!WARNING]\n> Careful here.")

      expect(result).to include("Careful here.")
      expect(result).not_to match(%r{data-alert-label="warning">Warning</p>\s*<p><br}m)
    end

    it "renders a normal blockquote without an alert attribute" do
      expect(rendered("> Just a quote.")).not_to include("data-alert")
    end
  end
end

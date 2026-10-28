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

    it "leaves a token joined directly to following text as a plain blockquote" do
      html = "<blockquote><p>[!NOTE]worthy of attention</p></blockquote>"
      result = transform(html)

      expect(result).not_to include("data-alert")
      expect(result).to include("[!NOTE]worthy of attention")
    end

    it "still tags a token followed by a space and body text" do
      result = transform("<blockquote><p>[!TIP] Body</p></blockquote>")

      expect(result).to include(%(data-alert="tip"))
      expect(result).to include("Body")
    end

    it "still tags a token followed by a line break element" do
      result = transform("<blockquote><p>[!TIP]<br>Body</p></blockquote>")

      expect(result).to include(%(data-alert="tip"))
      expect(result).not_to include("[!TIP]")
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

    context "when the token is not the leading text of the quote" do
      it "tags only the inner quote when quotes are nested" do
        result = transform("<blockquote><blockquote><p>[!TIP] Inner</p></blockquote></blockquote>")
        outer, inner = Nokogiri::HTML.fragment(result).css("blockquote").to_a

        expect(inner["data-alert"]).to eq("tip")
        expect(outer["data-alert"]).to be_nil
      end

      it "leaves a quote that opens with a heading" do
        result = transform("<blockquote><h2>Heading</h2><p>[!TIP] Body</p></blockquote>")

        expect(result).not_to include("data-alert")
        expect(result).to include("[!TIP]")
      end

      it "leaves a quote whose token sits inside inline code" do
        result = transform("<blockquote><p><code>[!NOTE]</code> is the alert syntax</p></blockquote>")

        expect(result).not_to include("data-alert")
        expect(result).to include("[!NOTE]")
      end
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

    it "does not treat a quote about the syntax as an alert" do
      result = rendered("> `[!NOTE]` is how GitHub writes an alert.")

      expect(result).not_to include("data-alert")
      expect(result).to include("[!NOTE]")
    end

    it "tags the inner quote when an alert is nested in a quote" do
      result = rendered("> > [!TIP]\n> > Inner body.")

      expect(result).to include(%(data-alert="tip"))
      expect(result).to include("Inner body.")
    end
  end
end

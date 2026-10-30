# frozen_string_literal: true

require "rails_helper"

RSpec.describe AsciidocToMarkdown, type: :service do
  describe ".call" do
    it "aliases .perform to .call" do
      expect(described_class.perform("= Title\n\nBody")).to eq(described_class.call("= Title\n\nBody"))
    end

    context "with empty or blank inputs" do
      it "returns an empty string when given empty text" do
        expect(described_class.call("")).to eq("")
      end

      it "returns an empty string when given nil or whitespace" do
        expect(described_class.call(nil)).to eq("")
        expect(described_class.call("   \n\n  ")).to eq("")
      end
    end

    context "with Forem Liquid tags" do
      it "preserves embed and social liquid tags intact without alteration" do
        input = <<~ADOC
          Check out this video:

          {% youtube dQw4w9WgXcQ %}

          And article link:
          {% embed https://dev.to/ben/announcing-something %}
        ADOC

        result = described_class.call(input)

        expect(result).to include("{% youtube dQw4w9WgXcQ %}")
        expect(result).to include("{% embed https://dev.to/ben/announcing-something %}")
      end

      it "preserves liquid variables {{ some_var }} without escaping" do
        input = "Value is {{ site.title }} in production."
        expect(described_class.call(input).strip).to eq(input)
      end
    end

    context "with Document Header and Forem Front Matter" do
      it "extracts document title and attributes into YAML Front Matter" do
        input = <<~ADOC
          = Building Reliable Services
          :author: Jane Developer
          :tags: ruby, rails, webdev
          :published: true

          Intro paragraph goes here.
        ADOC

        result = described_class.call(input, front_matter: true)

        expect(result).to start_with("---\n")
        expect(result).to include("title: Building Reliable Services")
        expect(result).to include("author: Jane Developer")
        expect(result).to include("tags: ruby, rails, webdev")
        expect(result).to include("published: 'true'")
        expect(result).to include("Intro paragraph goes here.")
      end

      it "renders an ATX H1 heading if front matter is disabled" do
        input = <<~ADOC
          = Pure Markdown Title

          Paragraph content.
        ADOC

        result = described_class.call(input, front_matter: false)

        expect(result).not_to include("---")
        expect(result).to start_with("# Pure Markdown Title")
      end

      it "restores Liquid tags in document metadata and front matter" do
        input = <<~ADOC
          = Guide to {% tag_name %} and {{ var }}
          :description: Info about {{ site.title }}
          :published: true

          Body text.
        ADOC

        result = described_class.call(input, front_matter: true)

        expect(result).to include("title: Guide to {% tag_name %} and {{ var }}")
        expect(result).to include("description: Info about {{ site.title }}")
      end
    end

    context "with Comments" do
      it "skips line comments and block comments in the document body" do
        input = <<~ADOC
          First paragraph.

          // This is a private single-line comment

          ////
          This is a private
          multi-line comment block
          ////

          Second paragraph.
        ADOC

        result = described_class.call(input)

        expect(result).to include("First paragraph.")
        expect(result).to include("Second paragraph.")
        expect(result).not_to include("private")
      end

      it "preserves comment slashes inside code blocks as literal code" do
        input = <<~ADOC
          [source,javascript]
          ----
          // Line comment in JS code
          console.log("hello");
          ----
        ADOC

        result = described_class.call(input)
        expect(result).to include("// Line comment in JS code")
      end

      it "closes comment block only with its exact matching delimiter" do
        input = <<~ADOC
          ////
          hidden comment
          //////
          still hidden comment
          ////
          Visible paragraph.
        ADOC

        result = described_class.call(input)

        expect(result).not_to include("hidden comment")
        expect(result).not_to include("still hidden comment")
        expect(result).to include("Visible paragraph.")
      end
    end

    context "with Code Listings" do
      it "converts source blocks with syntax highlighting language" do
        input = <<~ADOC
          [source,ruby]
          ----
          def calculate(a, b)
            a + b
          end
          ----
        ADOC

        expected = <<~MD
          ```ruby
          def calculate(a, b)
            a + b
          end
          ```
        MD

        expect(described_class.call(input).strip).to eq(expected.strip)
      end

      it "accepts extra attributes and special characters like # in source blocks" do
        input = <<~ADOC
          [source,c#,linenums]
          ----
          Console.WriteLine("Hello");
          ----
        ADOC

        result = described_class.call(input)
        expect(result).to start_with("```c#\nConsole.WriteLine(\"Hello\");\n```")
      end

      it "uses longer fence when code listing contains embedded markdown backticks" do
        input = <<~ADOC
          [source,markdown]
          ----
          Here is some markdown:
          ```ruby
          puts "nested"
          ```
          ----
        ADOC

        result = described_class.call(input).strip
        expect(result).to start_with("````markdown")
        expect(result).to end_with("````")
      end

      it "replaces callout numbers (<1>, <2>) in code blocks with unicode circled numbers" do
        input = <<~ADOC
          [source,javascript]
          ----
          const app = express(); <1>
          app.listen(3000); <2>
          ----
        ADOC

        result = described_class.call(input)

        expect(result).to include("const app = express(); ①")
        expect(result).to include("app.listen(3000); ②")
      end

      it "requires listing closing delimiter to match opening delimiter character and length" do
        input = <<~ADOC
          ----
          first code line
          ....
          second code line
          ----
        ADOC

        result = described_class.call(input)
        expect(result).to include("first code line\n....\nsecond code line")
      end

      it "emits buffered listing lines when input ends with an open listing block" do
        input = <<~ADOC
          [source,ruby]
          ----
          unclosed = true
          more_code = 1
        ADOC

        result = described_class.call(input)
        expect(result).to include("```ruby\nunclosed = true\nmore_code = 1\n```")
      end
    end

    context "with Tables" do
      it "converts AsciiDoc tables to GitHub-Flavored Markdown pipe tables" do
        input = <<~ADOC
          |===
          | Endpoint | Method | Description

          | /api/v1/users | GET | List all users
          | /api/v1/posts | POST | Create post
          |===
        ADOC

        expected = <<~MD
          | Endpoint | Method | Description |
          | --- | --- | --- |
          | /api/v1/users | GET | List all users |
          | /api/v1/posts | POST | Create post |
        MD

        expect(described_class.call(input).strip).to eq(expected.strip)
      end

      it "emits an empty GFM header row for tables without a header" do
        input = <<~ADOC
          |===
          | First | Middle | Last
          | John | | Doe
          | Escaped \\| Pipe | Mid | End
          |===
        ADOC

        expected = <<~MD
          |  |  |  |
          | --- | --- | --- |
          | First | Middle | Last |
          | John |  | Doe |
          | Escaped \\| Pipe | Mid | End |
        MD

        expect(described_class.call(input).strip).to eq(expected.strip)
      end

      it "promotes first row to header when options='header' is present" do
        input = <<~ADOC
          [options="header"]
          |===
          | First | Middle | Last
          | John | | Doe
          | Escaped \\| Pipe | Mid | End
          |===
        ADOC

        expected = <<~MD
          | First | Middle | Last |
          | --- | --- | --- |
          | John |  | Doe |
          | Escaped \\| Pipe | Mid | End |
        MD

        expect(described_class.call(input).strip).to eq(expected.strip)
      end
    end

    context "with Admonitions and Quotes" do
      it "converts single-line note/warning into blockquotes" do
        input = "NOTE: Always sanitize external input."
        expected = "> **Note:** Always sanitize external input."

        expect(described_class.call(input).strip).to eq(expected)
      end

      it "converts block admonition syntax [NOTE] and [WARNING]" do
        input = <<~ADOC
          [WARNING]
          ====
          Be careful with database migrations in production.
          ====
        ADOC

        result = described_class.call(input)
        expect(result).to include("> **Warning:**")
        expect(result).to include("Be careful with database migrations in production.")
      end

      it "converts blockquotes with optional author attribution" do
        input = <<~ADOC
          [quote, Matz, Ruby Creator]
          ____
          Ruby is designed to make programmers happy.

          Always prioritize developer happiness.
          ____
        ADOC

        result = described_class.call(input)

        expect(result).to include("> Ruby is designed to make programmers happy.")
        expect(result).to include(">\n> Always prioritize developer happiness.")
        expect(result).to include("> — Matz, Ruby Creator")
      end

      it "converts blockquotes without author attribution" do
        input = <<~ADOC
          ____
          Simplicity is a prerequisite for reliability.
          ____
        ADOC

        result = described_class.call(input)
        expect(result).to include("> Simplicity is a prerequisite for reliability.")
        expect(result).not_to include("—")
      end
    end

    context "with Headings and Lists" do
      it "converts nested section headings" do
        input = <<~ADOC
          == Major Section
          === Subsection
          ==== Detailed Heading
        ADOC

        expected = <<~MD
          ## Major Section
          ### Subsection
          #### Detailed Heading
        MD

        expect(described_class.call(input).strip).to eq(expected.strip)
      end

      it "converts ordered and unordered lists with correct indentation" do
        input = <<~ADOC
          * Top level bullet
          ** Nested bullet

          . Numbered item 1
          .. Numbered sub-item
        ADOC

        expected = <<~MD
          * Top level bullet
            * Nested bullet

          1. Numbered item 1
            1. Numbered sub-item
        MD

        expect(described_class.call(input).strip).to eq(expected.strip)
      end
    end

    context "with Inline Formatting and Links" do
      it "converts bold, italic, bold-italic, strikethrough, and mark tags" do
        input = "Check *bold*, _italic_, *_bold-italic_*, [.line-through]#strikethrough#, and #highlighted#."
        expected = "Check **bold**, *italic*, ***bold-italic***, ~~strikethrough~~, and <mark>highlighted</mark>."

        expect(described_class.call(input).strip).to eq(expected)
      end

      it "converts internal cross references and external links" do
        input = "See <<_prerequisites>> or visit https://forem.com[] or https://forem.com[Forem]."
        expected = "See [prerequisites](#prerequisites) or visit [https://forem.com](https://forem.com) or [Forem](https://forem.com)."

        expect(described_class.call(input).strip).to eq(expected)
      end

      it "leaves inline code spans untouched by formatting rules" do
        input = "Run `x = *a* + _b_` now."
        expect(described_class.call(input).strip).to eq(input)
      end

      it "does not apply emphasis inside link targets" do
        input = "See https://example.com/_docs_/*v1*[Docs]."
        expect(described_class.call(input).strip).to eq("See [Docs](https://example.com/_docs_/*v1*).")
      end

      it "keeps already-doubled asterisks as bold" do
        expect(described_class.call("Use **strong** text.").strip).to eq("Use **strong** text.")
      end

      it "does not highlight issue numbers, hashtags, or language names like C#" do
        input = "Fixes #123 in C# code, tagged #ruby and #rails."
        expect(described_class.call(input).strip).to eq(input)
      end

      it "keeps image alt text plain" do
        input = "image::a_b.png[My _alt_ text]\n\nInline image:c_d.png[*Logo*]"
        result = described_class.call(input)

        expect(result).to include("![My _alt_ text](a_b.png)")
        expect(result).to include("![*Logo*](c_d.png)")
      end

      it "drops standalone block anchor lines" do
        expect(described_class.call("[[intro]]\nIntro text.").strip).to eq("Intro text.")
      end

      it "keeps the custom label of a cross reference" do
        expect(described_class.call("See <<sec-1,Section One>>.").strip).to eq("See [Section One](#sec-1).")
      end

      it "substitutes attributes declared in the document body and honors unsetting" do
        input = <<~ADOC
          Intro.

          :product: Forem
          Built with {product}.
          :product!:
          Now {product}.
        ADOC

        result = described_class.call(input)

        expect(result).to include("Built with Forem.")
        expect(result).to include("Now {product}.")
        expect(result).not_to include(":product:")
      end

      it "does not confuse user text with internal placeholders" do
        input = "Literal <!--LIQUID_0--> and {{ var }} and `code`."
        expect(described_class.call(input).strip).to eq(input)
      end

      it "converts thematic breaks" do
        input = <<~ADOC
          Section 1

          '''

          Section 2
        ADOC

        result = described_class.call(input)
        expect(result).to include("---")
      end

      it "converts block images and inline images" do
        input = <<~ADOC
          image::https://dev.to/logo.png[DEV Logo]

          Inline badge: image:https://img.shields.io/badge[Status]
        ADOC

        result = described_class.call(input)

        expect(result).to include("![DEV Logo](https://dev.to/logo.png)")
        expect(result).to include("![Status](https://img.shields.io/badge)")
      end
    end
  end
end

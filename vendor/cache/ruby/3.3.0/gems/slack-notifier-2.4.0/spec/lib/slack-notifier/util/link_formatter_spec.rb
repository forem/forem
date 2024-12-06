# frozen_string_literal: true
# encoding: utf-8

# rubocop:disable Metrics/LineLength
RSpec.describe Slack::Notifier::Util::LinkFormatter do
  describe "initialize & formatted" do
    it "can be initialized without format args" do
      subject = described_class.new("Hello World")
      expect(subject.formatted()).to eq("Hello World")
    end

    it "can be initialized with format args" do
      subject = described_class.new("Hello World", formats: [:html])
      expect(subject.formatted()).to eq("Hello World")
    end
  end
  describe "::format" do
    it "formats html links" do
      formatted = described_class.format("Hello World, enjoy <a href='http://example.com'>this</a>.")
      expect(formatted).to include("<http://example.com|this>")
    end

    it "formats markdown links" do
      formatted = described_class.format("Hello World, enjoy [this](http://example.com).")
      expect(formatted).to include("<http://example.com|this>")
    end

    it "formats markdown links in brackets" do
      formatted = described_class.format("Hello World, enjoy [[this](http://example.com) in brackets].")
      expect(formatted).to eq("Hello World, enjoy [<http://example.com|this> in brackets].")
    end

    it "formats markdown links with no title" do
      formatted = described_class.format("Hello World, enjoy [](http://example.com).")
      expect(formatted).to include("<http://example.com>")
    end

    it "handles multiple html links" do
      formatted = described_class.format("Hello World, enjoy <a href='http://example.com'>this</a><a href='http://example2.com'>this2</a>.")
      expect(formatted).to include("<http://example.com|this>")
      expect(formatted).to include("<http://example2.com|this2>")
    end

    it "handles multiple markdown links" do
      formatted = described_class.format("Hello World, enjoy [this](http://example.com)[this2](http://example2.com).")
      expect(formatted).to include("<http://example.com|this>")
      expect(formatted).to include("<http://example2.com|this2>")
    end

    it "handles mixed html & markdown links" do
      formatted = described_class.format("Hello World, enjoy [this](http://example.com)<a href='http://example2.com'>this2</a>.")
      expect(formatted).to include("<http://example.com|this>")
      expect(formatted).to include("<http://example2.com|this2>")
    end

    if "".respond_to? :scrub
      context "when on ruby 2.1+ or have string-scrub installed" do
        it "handles invalid unicode sequences" do
          expect do
            described_class.format("This sequence is invalid: \255")
          end.not_to raise_error
        end

        it "replaces invalid unicode sequences with the unicode replacement character" do
          formatted = described_class.format("\255")
          expect(formatted).to eq "\uFFFD"
        end
      end
    end

    it "doesn't replace valid Japanese" do
      formatted = described_class.format("こんにちは")
      expect(formatted).to eq "こんにちは"
    end

    it "handles mailto links in markdown" do
      formatted = described_class.format("[John](mailto:john@example.com)")
      expect(formatted).to eq "<mailto:john@example.com|John>"
    end

    it "handles mailto links in html" do
      formatted = described_class.format("<a href='mailto:john@example.com'>John</a>")
      expect(formatted).to eq "<mailto:john@example.com|John>"
    end

    it "handles links with trailing parentheses" do
      formatted = described_class.format("Hello World, enjoy [foo(bar)](http://example.com/foo(bar))<a href='http://example.com/bar(foo)'>bar(foo)</a>")
      expect(formatted).to include("http://example.com/foo(bar)|foo(bar)")
      expect(formatted).to include("http://example.com/bar(foo)|bar(foo)")
    end

    it "formats a number of differently formatted links" do
      input_output = {
        "Hello World, enjoy [this](http://example.com)." =>
          "Hello World, enjoy <http://example.com|this>.",

        "Hello World, enjoy [[this](http://example.com) in brackets]." =>
          "Hello World, enjoy [<http://example.com|this> in brackets].",

        "Hello World, enjoy ([this](http://example.com) in parens)." =>
          "Hello World, enjoy (<http://example.com|this> in parens).",

        "Hello World, enjoy [](http://example.com)." =>
          "Hello World, enjoy <http://example.com>.",

        "Hello World, enjoy [link with query](http://example.com?foo=bar)." =>
          "Hello World, enjoy <http://example.com?foo=bar|link with query>.",

        "Hello World, enjoy [link with fragment](http://example.com/#foo-bar)." =>
          "Hello World, enjoy <http://example.com/#foo-bar|link with fragment>.",

        "Hello World, enjoy [link with parens](http://example.com/foo(bar)/baz)." =>
          "Hello World, enjoy <http://example.com/foo(bar)/baz|link with parens>.",

        "Hello World, enjoy [link with query](http://example.com/(parens)?foo=bar)." =>
          "Hello World, enjoy <http://example.com/(parens)?foo=bar|link with query>.",

        "Hello World, enjoy [link with parens](http://example.com/baz?bang=foo(bar))." =>
          "Hello World, enjoy <http://example.com/baz?bang=foo(bar)|link with parens>.",

        "Hello World, enjoy [link with fragment](http://example.com/(parens)#foo-bar)." =>
          "Hello World, enjoy <http://example.com/(parens)#foo-bar|link with fragment>.",

        "Hello World, enjoy [link with fragment](http://example.com/#foo-bar=(baz))." =>
          "Hello World, enjoy <http://example.com/#foo-bar=(baz)|link with fragment>.",

        "Hello World, enjoy [this](http://example.com?foo=bar)[this2](http://example2.com)." =>
          "Hello World, enjoy <http://example.com?foo=bar|this><http://example2.com|this2>.",

        "Hello World, enjoy [this](http://example.com?foo=bar) [this2](http://example2.com/#fragment)." =>
          "Hello World, enjoy <http://example.com?foo=bar|this> <http://example2.com/#fragment|this2>.",

        "Hello World, enjoy [this](http://example.com)<a href='http://example2.com'>this2</a>." =>
          "Hello World, enjoy <http://example.com|this><http://example2.com|this2>.",

        "Hello world, [John](mailto:john@example.com)." =>
          "Hello world, <mailto:john@example.com|John>.",

        "Hello World, enjoy [foo(bar)](http://example.com/foo(bar))<a href='http://example.com/bar(foo)'>bar(foo)</a>" =>
          "Hello World, enjoy <http://example.com/foo(bar)|foo(bar)><http://example.com/bar(foo)|bar(foo)>"
      }

      input_output.each do |input, output|
        expect(described_class.format(input)).to eq output
      end
    end

    context "with a configured stack" do
      it "only formats html if html is the only item in formats" do
        formatted = described_class.format("Hello World, enjoy [this](http://example.com)<a href='http://example2.com'>this2</a>.", formats: [:html])
        expect(formatted).to eq "Hello World, enjoy [this](http://example.com)<http://example2.com|this2>."
      end
      it "only formats markdown if markdown is the only item in formats" do
        formatted = described_class.format("Hello World, enjoy [this](http://example.com)<a href='http://example2.com'>this2</a>.", formats: [:markdown])
        expect(formatted).to eq "Hello World, enjoy <http://example.com|this><a href='http://example2.com'>this2</a>."
      end
      it "doesn't format if formats is empty" do
        formatted = described_class.format("Hello World, enjoy [this](http://example.com)<a href='http://example2.com'>this2</a>.", formats: [])
        expect(formatted).to eq "Hello World, enjoy [this](http://example.com)<a href='http://example2.com'>this2</a>."
      end
    end
  end
end

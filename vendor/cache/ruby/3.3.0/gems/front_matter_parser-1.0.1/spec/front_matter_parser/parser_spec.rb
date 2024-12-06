# frozen_string_literal: true

require 'spec_helper'

describe FrontMatterParser::Parser do
  let(:front_matter) { { 'title' => 'hello' } }
  let(:content) { "Content\n" }

  describe '#call' do
    let(:string) do
      <<~STRING
        <!--
        ---
        title: hello
        ---
        -->
        Content
      STRING
    end

    it 'parses using given parser' do
      parser = described_class.new(FrontMatterParser::SyntaxParser::Html.new)

      parsed = parser.call(string)

      expect(parsed).to be_parsed_result_with(front_matter, content)
    end

    it 'infers parser if it is a symbol' do
      parser = described_class.new(:html)

      parsed = parser.call(string)

      expect(parsed).to be_parsed_result_with(front_matter, content)
    end

    it 'parses front matter as an empty hash if it is not present' do
      string = 'Content'
      parser = described_class.new(:html)

      parsed = parser.call(string)

      expect(parsed.front_matter).to eq({})
    end

    it 'parses content as the whole string if front matter is not present' do
      string = 'Content'
      parser = described_class.new(:html)

      parsed = parser.call(string)

      expect(parsed.content).to eq(string)
    end

    it 'can specify custom front matter loader with loader: param' do
      front_matter = { 'a' => 'b' }
      parser = described_class.new(:html,
                                   loader: ->(_string) { front_matter })

      parsed = parser.call(string)

      expect(parsed.front_matter).to eq(front_matter)
    end
  end

  describe '::parse_file' do
    # :reek:UtilityFunction
    def pathname(file)
      File.expand_path("../../fixtures/#{file}", __FILE__)
    end

    it 'parses inferring syntax from given pathname' do
      pathname = pathname('example.html')

      parsed = described_class.parse_file(
        pathname
      )

      expect(parsed).to be_parsed_result_with(front_matter, content)
    end

    it 'can specify custom parser through :syntax_parser param' do
      pathname = pathname('example')

      parsed = described_class.parse_file(
        pathname, syntax_parser: FrontMatterParser::SyntaxParser::Html.new
      )

      expect(parsed).to be_parsed_result_with(front_matter, content)
    end

    it 'can specify custom parser as symbol through :syntax_parser param' do
      pathname = pathname('example')

      parsed = described_class.parse_file(
        pathname, syntax_parser: :html
      )

      expect(parsed).to be_parsed_result_with(front_matter, content)
    end

    it 'can specify custom front matter loader with loader: param' do
      pathname = pathname('example.html')
      front_matter = { 'a' => 'b' }
      parsed = described_class.parse_file(pathname,
                                          loader: ->(_string) { front_matter })

      expect(parsed.front_matter).to eq(front_matter)
    end
  end
end

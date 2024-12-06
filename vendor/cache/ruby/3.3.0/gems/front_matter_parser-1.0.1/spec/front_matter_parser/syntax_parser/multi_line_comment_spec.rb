# frozen_string_literal: true

require 'spec_helper'

describe FrontMatterParser::SyntaxParser::MultiLineComment do
  subject(:parsed) { FrontMatterParser::Parser.new(syntax).call(string) }

  let(:front_matter) { { 'title' => 'hello', 'author' => 'me' } }
  let(:content) { "Content\n" }

  context 'when syntax is html' do
    let(:syntax) { :html }
    let(:string) do
      <<~STRING
        <!--
        ---
        title: hello
        author: me
        ---
        -->
        Content
      STRING
    end

    it 'can parse it' do
      expect(parsed).to be_parsed_result_with(front_matter, content)
    end
  end

  context 'when syntax is erb' do
    let(:syntax) { :erb }
    let(:string) do
      <<~STRING
        <%#
        ---
        title: hello
        author: me
        ---
        %>
        Content
      STRING
    end

    it 'can parse it' do
      expect(parsed).to be_parsed_result_with(front_matter, content)
    end
  end

  context 'when syntax is liquid' do
    let(:syntax) { :liquid }
    let(:string) do
      <<~STRING
        {% comment %}
        ---
        title: hello
        author: me
        ---
        {% endcomment %}
        Content
      STRING
    end

    it 'can parse it' do
      expect(parsed).to be_parsed_result_with(front_matter, content)
    end
  end

  context 'when syntax is md' do
    let(:syntax) { :md }
    let(:string) do
      <<~STRING
        ---
        title: hello
        author: me
        ---
        Content
      STRING
    end

    it 'can parse it' do
      expect(parsed).to be_parsed_result_with(front_matter, content)
    end
  end

  context 'with space before start comment delimiter' do
    let(:syntax) { :html }
    let(:string) do
      <<~STRING

           <!--
        ---
        title: hello
        author: me
        ---
        -->
        Content
      STRING
    end

    it 'can parse it' do
      expect(parsed).to be_parsed_result_with(front_matter, content)
    end
  end

  context 'with front matter starting in comment delimiter line' do
    let(:syntax) { :html }
    let(:string) do
      <<~STRING
        <!-- ---
        title: hello
        author: me
        ---
        -->
        Content
      STRING
    end

    it 'can parse it' do
      expect(parsed).to be_parsed_result_with(front_matter, content)
    end
  end

  context 'with space before front matter' do
    let(:syntax) { :html }
    let(:string) do
      <<~STRING
        <!--

           ---
        title: hello
        author: me
        ---
        -->
        Content
      STRING
    end

    it 'can parse it' do
      expect(parsed).to be_parsed_result_with(front_matter, content)
    end
  end

  context 'with space within front matter' do
    let(:syntax) { :html }
    let(:string) do
      <<~STRING
        <!--
        ---
          title: hello

          author: me
        ---
        -->
        Content
      STRING
    end

    it 'can parse it' do
      expect(parsed).to be_parsed_result_with(front_matter, content)
    end
  end

  context 'with space after front matter' do
    let(:syntax) { :html }
    let(:string) do
      <<~STRING
        <!--
        ---
        title: hello
        author: me
        ---

        -->
        Content
      STRING
    end

    it 'can parse it' do
      expect(parsed).to be_parsed_result_with(front_matter, content)
    end
  end

  context 'with space before end comment delimiter' do
    let(:syntax) { :html }
    let(:string) do
      <<~STRING
        <!--
        ---
        title: hello
        author: me
        ---
           -->
        Content
      STRING
    end

    it 'can parse it' do
      expect(parsed).to be_parsed_result_with(front_matter, content)
    end
  end

  context 'with start comment delimiter in the front matter' do
    let(:syntax) { :html }
    let(:string) do
      <<~STRING
        <!--
        ---
        title: <!--hello
        author: me
        ---
           -->
        Content
      STRING
    end

    it 'can parse it' do
      front_matter = { 'title' => '<!--hello', 'author' => 'me' }

      expect(parsed).to be_parsed_result_with(front_matter, content)
    end
  end

  context 'with start and end comment delimiter in the front matter' do
    let(:syntax) { :html }
    let(:string) do
      <<~STRING
        <!--
        ---
        title: <!--hello-->
        author: me
        ---
           -->
        Content
      STRING
    end

    it 'can parse it' do
      front_matter = { 'title' => '<!--hello-->', 'author' => 'me' }

      expect(parsed).to be_parsed_result_with(front_matter, content)
    end
  end

  context 'with front matter delimiter chars in the content' do
    let(:syntax) { :md }
    let(:string) do
      <<~STRING
        ---
        title: hello
        ---
        Content---
      STRING
    end

    it 'is not greedy' do
      front_matter = { 'title' => 'hello' }

      expect(parsed).to be_parsed_result_with(front_matter, "Content---\n")
    end
  end

  it 'returns nil if no front matter is found' do
    string = 'Content'

    expect(FrontMatterParser::SyntaxParser::Html.new.call(string)).to be_nil
  end
end

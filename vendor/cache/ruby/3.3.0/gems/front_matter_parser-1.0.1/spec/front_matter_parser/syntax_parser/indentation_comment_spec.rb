# frozen_string_literal: true

require 'spec_helper'

describe FrontMatterParser::SyntaxParser::IndentationComment do
  subject(:parsed) { FrontMatterParser::Parser.new(syntax).call(string) }

  let(:front_matter) { { 'title' => 'hello', 'author' => 'me' } }
  let(:content) { "Content\n" }

  context 'when syntax is slim' do
    let(:syntax) { :slim }
    let(:string) do
      <<~STRING
        /
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

  context 'when syntax is haml' do
    let(:syntax) { :haml }
    let(:string) do
      <<~STRING
        -#
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

  context 'with space before comment delimiter' do
    let(:syntax) { :slim }
    let(:string) do
      <<~STRING

          /
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

  context 'with front matter starting in comment delimiter line' do
    let(:syntax) { :slim }
    let(:string) do
      <<~STRING
        /---
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

  context 'with space before front matter' do
    let(:syntax) { :slim }
    let(:string) do
      <<~STRING
        /

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

  context 'with space within front matter' do
    let(:syntax) { :slim }
    let(:string) do
      <<~STRING
        /
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

  context 'with comment delimiter in the front matter' do
    let(:syntax) { :slim }
    let(:string) do
      <<~STRING
        /
         ---
         title: /hello
         author: me
         ---
        Content
      STRING
    end

    it 'can parse it' do
      front_matter = { 'title' => '/hello', 'author' => 'me' }

      expect(parsed).to be_parsed_result_with(front_matter, content)
    end
  end

  context 'with front matter delimiter chars in the content' do
    let(:syntax) { :slim }
    let(:string) do
      <<~STRING
        /
         ---
         title: hello
         ---
        Content
        ---
      STRING
    end

    it 'is not greedy' do
      front_matter = { 'title' => 'hello' }

      expect(parsed).to be_parsed_result_with(front_matter, "Content\n---\n")
    end
  end

  it 'returns nil if no front matter is found' do
    string = 'Content'

    expect(FrontMatterParser::SyntaxParser::Slim.new.call(string)).to be_nil
  end
end

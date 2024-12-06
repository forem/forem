require 'spec_helper'

describe MetaInspector do
  it "should get the title from the head section" do
    page = MetaInspector.new('http://example.com')
    expect(page.title).to eq('An example page')
  end

  describe "#h1" do 
    it "should find h1 content" do
      page = MetaInspector.new('http://example.com/headings')
      expect(page.h1.first).to eq('H1')
    end
  end

  describe "#h2" do 
    it "should find h2 content" do
      page = MetaInspector.new('http://example.com/headings')
      expect(page.h2.first).to eq('H2')
    end
  end

  describe "#h3" do 
    it "should find h3 content" do
      page = MetaInspector.new('http://example.com/headings')
      expect(page.h3.first).to eq('H3')
    end
  end

  describe "#h4" do 
    it "should find h4 content" do
      page = MetaInspector.new('http://example.com/headings')
      expect(page.h4.first).to eq('H4')
    end
  end

  describe "#h5" do 
    it "should find h5 content" do
      page = MetaInspector.new('http://example.com/headings')
      expect(page.h5.first).to eq('H5')
    end
  end

  describe "#h6" do 
    it "should find h6 content" do
      page = MetaInspector.new('http://example.com/headings')
      expect(page.h6.first).to eq('H6')
    end
  end

  describe '#best_title' do
    it "should find 'head title' when that's the only thing" do
      page = MetaInspector.new('http://example.com/title_in_head')
      expect(page.best_title).to eq('This title came from the head')
    end

    it "should find 'body title' when that's the only thing" do
      page = MetaInspector.new('http://example.com/title_in_body')
      expect(page.best_title).to eq('This title came from the body, not the head')
    end

    it "should find 'og:title' when that's the only thing" do
      page = MetaInspector.new('http://example.com/meta-tags')
      expect(page.best_title).to eq('An OG title')
    end

    it "should find the first <h1> when that's the only thing" do
      page = MetaInspector.new('http://example.com/title_in_h1')
      expect(page.best_title).to eq('This title came from the first h1')
    end

    it "should choose the best candidate from the available options" do
      page = MetaInspector.new('http://example.com/title_best_choice')
      expect(page.best_title).to eq('This OG title is the best choice, as per web standards.')
    end

    it "should strip leading and trailing whitespace and all line breaks" do
      page = MetaInspector.new('http://example.com/title_in_head_with_whitespace')
      expect(page.best_title).to eq('This title came from the head and has leading and trailing whitespace')
    end

    it "should return nil if none of the candidates are present" do
      page = MetaInspector.new('http://example.com/title_not_present')
      expect(page.best_title).to be(nil)
    end
  end

  describe '#author' do
    it "should find author from meta author" do
      page = MetaInspector.new('http://example.com/author_in_meta')

      expect(page.author).to eq("the author")
    end

    it "should be nil if no meta author" do
      page = MetaInspector.new('http://example.com/empty')

      expect(page.author).to be(nil)
    end
  end

  describe "#best_author" do
    it "should return the author meta tag content if present" do
      page = MetaInspector.new('http://example.com/author_in_meta')

      expect(page.best_author).to eq("the author")
    end

    it "should find a link with the relational attribute author if standard meta tag is not present" do
      page = MetaInspector.new('http://example.com/author_in_link')
      expect(page.best_author).to eq("This author came from a link with the author relational attribute")
    end

    it "should find the address tag if standard meta tag and relational attribute author are not present" do
      page = MetaInspector.new('http://example.com/author_in_body')
      expect(page.best_author).to eq("This author came from the address tag")
    end

    it "should return the twitter creator if address tag not present" do
      page = MetaInspector.new('http://example.com/author_in_twitter')

      expect(page.best_author).to eq("This author came from the twitter creator tag")
    end

    it "should return nil if no author information present" do
      page = MetaInspector.new('http://example.com/empty')

      expect(page.best_author).to be(nil)
    end
  end

  describe '#description' do
    it "should find description from meta description" do
      page = MetaInspector.new('http://example.com/desc_in_meta')

      expect(page.description).to eq("the standard description")
    end

    it "should be nil if no meta description" do
      page = MetaInspector.new('http://example.com/empty')

      expect(page.description).to be(nil)
    end
  end

  describe "#best_description" do
    it "should return the standard description meta tag content if present" do
      page = MetaInspector.new('http://example.com/desc_in_meta')

      expect(page.best_description).to eq("the standard description")
    end

    it "should return the og description if standard meta tag is not present" do
      page = MetaInspector.new('http://example.com/desc_in_og')

      expect(page.best_description).to eq("the og description")
    end

    it "should return the twitter description if standard and og tag not present" do
      page = MetaInspector.new('http://example.com/desc_in_twitter')

      expect(page.best_description).to eq("the twitter description")
    end

    it "should return the secondary description if no meta tag is present" do
      page = MetaInspector.new('http://theonion-no-description.com')

      expect(page.best_description).to eq("SAN FRANCISCO—In a move expected to revolutionize the mobile device industry, Apple launched its fastest and most powerful iPhone to date Tuesday, an innovative new model that can only be seen by the company's hippest and most dedicated customers. This is secondary text picked up because of a missing meta description.")
    end

    it "should return nil by default" do
      page = MetaInspector.new('http://example.com/empty')

      expect(page.best_description).to be(nil)
    end
  end
end

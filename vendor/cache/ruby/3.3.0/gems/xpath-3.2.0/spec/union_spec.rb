# frozen_string_literal: true

require 'spec_helper'

describe XPath::Union do
  let(:template) { File.read(File.expand_path('fixtures/simple.html', File.dirname(__FILE__))) }
  let(:doc) { Nokogiri::HTML(template) }

  describe '#expressions' do
    it 'should return the expressions' do
      @expr1 = XPath.generate { |x| x.descendant(:p) }
      @expr2 = XPath.generate { |x| x.descendant(:div) }
      @collection = XPath::Union.new(@expr1, @expr2)
      @collection.expressions.should eq [@expr1, @expr2]
    end
  end

  describe '#each' do
    it 'should iterate through the expressions' do
      @expr1 = XPath.generate { |x| x.descendant(:p) }
      @expr2 = XPath.generate { |x| x.descendant(:div) }
      @collection = XPath::Union.new(@expr1, @expr2)
      exprs = []
      @collection.each { |expr| exprs << expr }
      exprs.should eq [@expr1, @expr2]
    end
  end

  describe '#map' do
    it 'should map the expressions' do
      @expr1 = XPath.generate { |x| x.descendant(:p) }
      @expr2 = XPath.generate { |x| x.descendant(:div) }
      @collection = XPath::Union.new(@expr1, @expr2)
      @collection.map(&:expression).should eq %i[descendant descendant]
    end
  end

  describe '#to_xpath' do
    it 'should create a valid xpath expression' do
      @expr1 = XPath.generate { |x| x.descendant(:p) }
      @expr2 = XPath.generate { |x| x.descendant(:div).where(x.attr(:id) == 'foo') }
      @collection = XPath::Union.new(@expr1, @expr2)
      @results = doc.xpath(@collection.to_xpath)
      @results[0][:title].should eq 'fooDiv'
      @results[1].text.should eq 'Blah'
      @results[2].text.should eq 'Bax'
    end
  end

  describe '#where and others' do
    it 'should be delegated to the individual expressions' do
      @expr1 = XPath.generate { |x| x.descendant(:p) }
      @expr2 = XPath.generate { |x| x.descendant(:div) }
      @collection = XPath::Union.new(@expr1, @expr2)
      @xpath1 = @collection.where(XPath.attr(:id) == 'foo').to_xpath
      @xpath2 = @collection.where(XPath.attr(:id) == 'fooDiv').to_xpath
      @results = doc.xpath(@xpath1)
      @results[0][:title].should eq 'fooDiv'
      @results = doc.xpath(@xpath2)
      @results[0][:id].should eq 'fooDiv'
    end
  end
end

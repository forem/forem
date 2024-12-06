# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Capybara::Selector::CSS::Splitter do
  let :splitter do
    ::Capybara::Selector::CSS::Splitter.new
  end

  context 'split not needed' do
    it 'normal CSS selector' do
      css = 'div[id="abc"]'
      expect(splitter.split(css)).to eq [css]
    end

    it 'comma in strings' do
      css = 'div[id="a,bc"]'
      expect(splitter.split(css)).to eq [css]
    end

    it 'comma in pseudo-selector' do
      css = 'div.class1:not(.class1, .class2)'
      expect(splitter.split(css)).to eq [css]
    end
  end

  context 'split needed' do
    it 'root level comma' do
      css = 'div.class1, span, p.class2'
      expect(splitter.split(css)).to eq ['div.class1', 'span', 'p.class2']
    end

    it 'root level comma when quotes and pseudo selectors' do
      css = 'div.class1[id="abc\\"def,ghi"]:not(.class3, .class4), span[id=\'a"c\\\'de\'], section, #abc\\,def'
      expect(splitter.split(css)).to eq ['div.class1[id="abc\\"def,ghi"]:not(.class3, .class4)', 'span[id=\'a"c\\\'de\']', 'section', '#abc\\,def']
    end
  end
end

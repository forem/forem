# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/InstanceVariable
RSpec.describe Capybara::Selector::XPathBuilder do
  let :builder do
    ::Capybara::Selector::XPathBuilder.new(@xpath)
  end

  context 'add_attribute_conditions' do
    it 'adds a single string condition to a single selector' do
      @xpath = './/div'
      selector = builder.add_attribute_conditions(random: 'abc')
      expect(selector).to eq %((.//div)[(./@random = 'abc')])
    end

    it 'adds multiple string conditions to a single selector' do
      @xpath = './/div'
      selector = builder.add_attribute_conditions(random: 'abc', other: 'def')
      expect(selector).to eq %(((.//div)[(./@random = 'abc')])[(./@other = 'def')])
    end

    it 'adds a single string condition to a multiple selector' do
      @xpath = XPath.descendant(:div, :ul)
      selector = builder.add_attribute_conditions(random: 'abc')
      expect(selector.to_s).to eq @xpath[XPath.attr(:random) == 'abc'].to_s
    end

    it 'adds multiple string conditions to a multiple selector' do
      @xpath = XPath.descendant(:div, :ul)
      selector = builder.add_attribute_conditions(random: 'abc', other: 'def')
      expect(selector.to_s).to eq %(.//*[self::div | self::ul][(./@random = 'abc')][(./@other = 'def')])
    end

    it 'adds simple regexp conditions to a single selector' do
      @xpath = XPath.descendant(:div)
      selector = builder.add_attribute_conditions(random: /abc/, other: /def/)
      expect(selector.to_s).to eq %(.//div[./@random[contains(., 'abc')]][./@other[contains(., 'def')]])
    end

    it 'adds wildcard regexp conditions to a single selector' do
      @xpath = './/div'
      selector = builder.add_attribute_conditions(random: /abc.*def/, other: /def.*ghi/)
      expect(selector).to eq %(((.//div)[./@random[(contains(., 'abc') and contains(., 'def'))]])[./@other[(contains(., 'def') and contains(., 'ghi'))]])
    end

    it 'adds alternated regexp conditions to a single selector' do
      @xpath = XPath.descendant(:div)
      selector = builder.add_attribute_conditions(random: /abc|def/, other: /def|ghi/)
      expect(selector.to_s).to eq %(.//div[./@random[(contains(., 'abc') or contains(., 'def'))]][./@other[(contains(., 'def') or contains(., 'ghi'))]])
    end

    it 'adds alternated regexp conditions to a multiple selector' do
      @xpath = XPath.descendant(:div, :ul)
      selector = builder.add_attribute_conditions(other: /def.*ghi|jkl/)
      expect(selector.to_s).to eq %(.//*[self::div | self::ul][./@other[((contains(., 'def') and contains(., 'ghi')) or contains(., 'jkl'))]])
    end

    it "returns original selector when regexp can't be substringed" do
      @xpath = './/div'
      selector = builder.add_attribute_conditions(other: /.+/)
      expect(selector).to eq '(.//div)[./@other]'
    end

    context ':class' do
      it 'handles string' do
        @xpath = './/a'
        selector = builder.add_attribute_conditions(class: 'my_class')
        expect(selector).to eq %((.//a)[contains(concat(' ', normalize-space(./@class), ' '), ' my_class ')])
      end

      it 'handles negated strings' do
        @xpath = XPath.descendant(:a)
        selector = builder.add_attribute_conditions(class: '!my_class')
        expect(selector.to_s).to eq @xpath[!XPath.attr(:class).contains_word('my_class')].to_s
      end

      it 'handles array of strings' do
        @xpath = './/a'
        selector = builder.add_attribute_conditions(class: %w[my_class my_other_class])
        expect(selector).to eq %((.//a)[(contains(concat(' ', normalize-space(./@class), ' '), ' my_class ') and contains(concat(' ', normalize-space(./@class), ' '), ' my_other_class '))])
      end

      it 'handles array of string when negated included' do
        @xpath = XPath.descendant(:a)
        selector = builder.add_attribute_conditions(class: %w[my_class !my_other_class])
        expect(selector.to_s).to eq @xpath[XPath.attr(:class).contains_word('my_class') & !XPath.attr(:class).contains_word('my_other_class')].to_s
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable

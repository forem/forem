# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/InstanceVariable
RSpec.describe Capybara::Selector::CSSBuilder do
  let :builder do
    ::Capybara::Selector::CSSBuilder.new(@css)
  end

  context 'add_attribute_conditions' do
    it 'adds a single string condition to a single selector' do
      @css = 'div'
      selector = builder.add_attribute_conditions(random: 'abc')
      expect(selector).to eq %(div[random='abc'])
    end

    it 'adds multiple string conditions to a single selector' do
      @css = 'div'
      selector = builder.add_attribute_conditions(random: 'abc', other: 'def')
      expect(selector).to eq %(div[random='abc'][other='def'])
    end

    it 'adds a single string condition to a multiple selector' do
      @css = 'div, ul'
      selector = builder.add_attribute_conditions(random: 'abc')
      expect(selector).to eq %(div[random='abc'], ul[random='abc'])
    end

    it 'adds multiple string conditions to a multiple selector' do
      @css = 'div, ul'
      selector = builder.add_attribute_conditions(random: 'abc', other: 'def')
      expect(selector).to eq %(div[random='abc'][other='def'], ul[random='abc'][other='def'])
    end

    it 'adds simple regexp conditions to a single selector' do
      @css = 'div'
      selector = builder.add_attribute_conditions(random: /abc/, other: /def/)
      expect(selector).to eq %(div[random*='abc'][other*='def'])
    end

    it 'adds wildcard regexp conditions to a single selector' do
      @css = 'div'
      selector = builder.add_attribute_conditions(random: /abc.*def/, other: /def.*ghi/)
      expect(selector).to eq %(div[random*='abc'][random*='def'][other*='def'][other*='ghi'])
    end

    it 'adds alternated regexp conditions to a single selector' do
      @css = 'div'
      selector = builder.add_attribute_conditions(random: /abc|def/, other: /def|ghi/)
      expect(selector).to eq %(div[random*='abc'][other*='def'], div[random*='abc'][other*='ghi'], div[random*='def'][other*='def'], div[random*='def'][other*='ghi'])
    end

    it 'adds alternated regexp conditions to a multiple selector' do
      @css = 'div,ul'
      selector = builder.add_attribute_conditions(other: /def.*ghi|jkl/)
      expect(selector).to eq %(div[other*='def'][other*='ghi'], div[other*='jkl'], ul[other*='def'][other*='ghi'], ul[other*='jkl'])
    end

    it "returns original selector when regexp can't be substringed" do
      @css = 'div'
      selector = builder.add_attribute_conditions(other: /.+/)
      expect(selector).to eq 'div'
    end

    context ':class' do
      it 'handles string with CSS .' do
        @css = 'a'
        selector = builder.add_attribute_conditions(class: 'my_class')
        expect(selector).to eq 'a.my_class'
      end

      it 'handles negated string with CSS .' do
        @css = 'a'
        selector = builder.add_attribute_conditions(class: '!my_class')
        expect(selector).to eq 'a:not(.my_class)'
      end

      it 'handles array of string with CSS .' do
        @css = 'a'
        selector = builder.add_attribute_conditions(class: %w[my_class my_other_class])
        expect(selector).to eq 'a.my_class.my_other_class'
      end

      it 'handles array of string with CSS . when negated included' do
        @css = 'a'
        selector = builder.add_attribute_conditions(class: %w[my_class !my_other_class])
        expect(selector).to eq 'a.my_class:not(.my_other_class)'
      end
    end

    context ':id' do
      it 'handles string with CSS #' do
        @css = 'ul'
        selector = builder.add_attribute_conditions(id: 'my_id')
        expect(selector).to eq 'ul#my_id'
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable

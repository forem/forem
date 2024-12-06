# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Capybara::Result do
  let :string do
    Capybara.string <<-STRING
      <ul>
        <li>Alpha</li>
        <li>Beta</li>
        <li>Gamma</li>
        <li>Delta</li>
      </ul>
    STRING
  end

  let :result do
    string.all '//li', minimum: 0 # pass minimum: 0 so lazy evaluation doesn't get triggered yet
  end

  it 'has a length' do
    expect(result.length).to eq(4)
  end

  it 'has a first element' do
    result.first.text == 'Alpha'
  end

  it 'has a last element' do
    result.last.text == 'Delta'
  end

  it 'can supports values_at method' do
    expect(result.values_at(0, 2).map(&:text)).to eq(%w[Alpha Gamma])
  end

  it 'can return an element by its index' do
    expect(result.at(1).text).to eq('Beta')
    expect(result[2].text).to eq('Gamma')
  end

  it 'can be mapped' do
    expect(result.map(&:text)).to eq(%w[Alpha Beta Gamma Delta])
  end

  it 'can be selected' do
    expect(result.count do |element|
      element.text.include? 't'
    end).to eq(2)
  end

  it 'can be reduced' do
    expect(result.reduce('') do |memo, element|
      memo + element.text[0]
    end).to eq('ABGD')
  end

  it 'can be sampled' do
    expect(result).to include(result.sample)
  end

  it 'can be indexed' do
    expect(result.index do |el|
      el.text == 'Gamma'
    end).to eq(2)
  end

  def recalc_result
    string.all '//li', minimum: 0 # pass minimum: 0 so lazy evaluation doesn't get triggered yet
  end

  it 'supports all modes of []' do
    expect(recalc_result[1].text).to eq 'Beta'
    expect(recalc_result[0, 2].map(&:text)).to eq %w[Alpha Beta]
    expect(recalc_result[1..3].map(&:text)).to eq %w[Beta Gamma Delta]
    expect(recalc_result[-1].text).to eq 'Delta'
    expect(recalc_result[-2, 3].map(&:text)).to eq %w[Gamma Delta]
    expect(recalc_result[1...3].map(&:text)).to eq %w[Beta Gamma]
    expect(recalc_result[1..7].map(&:text)).to eq %w[Beta Gamma Delta]
    expect(recalc_result[2...-1].map(&:text)).to eq %w[Gamma]
    expect(recalc_result[2..-1].map(&:text)).to eq %w[Gamma Delta] # rubocop:disable Style/SlicingWithRange
    expect(recalc_result[2..].map(&:text)).to eq %w[Gamma Delta]
  end

  it 'supports endless ranges' do
    expect(result[2..].map(&:text)).to eq %w[Gamma Delta]
  end

  it 'supports inclusive positive beginless ranges' do
    expect(result[..2].map(&:text)).to eq %w[Alpha Beta Gamma]
  end

  it 'supports inclusive negative beginless ranges' do
    expect(result[..-2].map(&:text)).to eq %w[Alpha Beta Gamma]
    expect(result[..-1].map(&:text)).to eq %w[Alpha Beta Gamma Delta]
  end

  it 'supports exclusive positive beginless ranges' do
    expect(result[...2].map(&:text)).to eq %w[Alpha Beta]
  end

  it 'supports exclusive negative beginless ranges' do
    expect(result[...-2].map(&:text)).to eq %w[Alpha Beta]
    expect(result[...-1].map(&:text)).to eq %w[Alpha Beta Gamma]
  end

  it 'works with filter blocks' do
    result = string.all('//li') { |node| node.text == 'Alpha' }
    expect(result.size).to eq 1
  end

  # Not a great test but it indirectly tests what is needed
  it 'should evaluate filters lazily for idx' do
    skip 'JRuby has an issue with lazy enumerator evaluation' if jruby_lazy_enumerator_workaround?
    # Not processed until accessed
    expect(result.instance_variable_get(:@result_cache).size).to be 0

    # Only one retrieved when needed
    result.first
    expect(result.instance_variable_get(:@result_cache).size).to be 1

    # works for indexed access
    result[0]
    expect(result.instance_variable_get(:@result_cache).size).to be 1

    result[2]
    expect(result.instance_variable_get(:@result_cache).size).to be 3

    # All cached when converted to array
    result.to_a
    expect(result.instance_variable_get(:@result_cache).size).to eq 4
  end

  it 'should evaluate filters lazily for range' do
    skip 'JRuby has an issue with lazy enumerator evaluation' if jruby_lazy_enumerator_workaround?
    result[0..1]
    expect(result.instance_variable_get(:@result_cache).size).to be 2

    expect(result[0..7].size).to eq 4
    expect(result.instance_variable_get(:@result_cache).size).to be 4
  end

  it 'should evaluate filters lazily for idx and length' do
    skip 'JRuby has an issue with lazy enumerator evaluation' if jruby_lazy_enumerator_workaround?
    result[1, 2]
    expect(result.instance_variable_get(:@result_cache).size).to be 3

    expect(result[2, 5].size).to eq 2
    expect(result.instance_variable_get(:@result_cache).size).to be 4
  end

  it 'should only need to evaluate one result for any?' do
    skip 'JRuby has an issue with lazy enumerator evaluation' if jruby_lazy_enumerator_workaround?
    result.any?
    expect(result.instance_variable_get(:@result_cache).size).to be 1
  end

  it 'should evaluate all elements when #to_a called' do
    # All cached when converted to array
    result.to_a
    expect(result.instance_variable_get(:@result_cache).size).to eq 4
  end

  describe '#each' do
    it 'lazily evaluates' do
      skip 'JRuby has an issue with lazy enumerator evaluation' if jruby_lazy_enumerator_workaround?
      results = []
      result.each do |el|
        results << el
        expect(result.instance_variable_get(:@result_cache).size).to eq results.size
      end

      expect(results.size).to eq 4
    end

    context 'without a block' do
      it 'returns an iterator' do
        expect(result.each).to be_a(Enumerator)
      end

      it 'lazily evaluates' do
        skip 'JRuby has an issue with lazy enumerator evaluation' if jruby_lazy_enumerator_workaround?
        result.each.with_index do |_el, idx|
          expect(result.instance_variable_get(:@result_cache).size).to eq(idx + 1) # 0 indexing
        end
      end
    end
  end

  def jruby_lazy_enumerator_workaround?
    RUBY_PLATFORM == 'java'
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Capybara::Selector::FilterSet do
  after do
    described_class.remove(:test)
  end

  it 'allows node filters' do
    fs = described_class.add(:test) do
      node_filter(:node_test, :boolean) { |_node, _value| true }
      expression_filter(:expression_test, :boolean) { |_expr, _value| true }
    end

    expect(fs.node_filters.keys).to include(:node_test)
    expect(fs.node_filters.keys).not_to include(:expression_test)
  end

  it 'allows expression filters' do
    fs = described_class.add(:test) do
      node_filter(:node_test, :boolean) { |_node, _value| true }
      expression_filter(:expression_test, :boolean) { |_expr, _value| true }
    end

    expect(fs.expression_filters.keys).to include(:expression_test)
    expect(fs.expression_filters.keys).not_to include(:node_test)
  end

  it 'allows node filter and expression filter with the same name' do
    fs = described_class.add(:test) do
      node_filter(:test, :boolean) { |_node, _value| true }
      expression_filter(:test, :boolean) { |_expr, _value| true }
    end

    expect(fs.expression_filters[:test]).not_to eq fs.node_filters[:test]
  end

  it 'allows `filter` as an alias of `node_filter`' do
    fs = described_class.add(:test) do
      filter(:node_test, :boolean) { |_node, _value| true }
    end

    expect(fs.node_filters.keys).to include(:node_test)
  end
end

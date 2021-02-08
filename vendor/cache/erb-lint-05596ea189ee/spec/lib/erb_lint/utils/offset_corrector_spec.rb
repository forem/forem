# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Utils::OffsetCorrector do
  let(:processed_source) { ERBLint::ProcessedSource.new('file.rb', '<%= "" %>') }

  it 'supports node as argument' do
    described_class
      .new(processed_source, double(:corrector, remove: true), 0, 0..1)
      .remove(node)
  end

  private

  def node
    parser = Parser::CurrentRuby.new(RuboCop::AST::Builder.new)
    parser.parse(Parser::Source::Buffer.new('(string)').tap { |buffer| buffer.source = '""' })
  end
end

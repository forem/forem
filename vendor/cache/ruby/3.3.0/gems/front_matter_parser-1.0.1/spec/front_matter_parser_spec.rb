# frozen_string_literal: true

require 'spec_helper'

describe FrontMatterParser do
  it 'has a version number' do
    expect(FrontMatterParser::VERSION).not_to be_nil
  end
end

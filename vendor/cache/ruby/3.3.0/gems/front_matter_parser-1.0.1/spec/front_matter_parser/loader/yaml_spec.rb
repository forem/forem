# frozen_string_literal: true

require 'spec_helper'

describe FrontMatterParser::Loader::Yaml do
  describe '#call' do
    it 'loads using yaml parser' do
      string = "title: 'hello'"

      expect(described_class.new.call(string)).to eq(
        'title' => 'hello'
      )
    end

    it 'loads with classes in allowlist' do
      string = 'timestamp: 2017-10-17 00:00:00Z'
      params = { allowlist_classes: [Time] }

      expect(described_class.new(**params).call(string)).to eq(
        'timestamp' => Time.parse('2017-10-17 00:00:00Z')
      )
    end
  end
end

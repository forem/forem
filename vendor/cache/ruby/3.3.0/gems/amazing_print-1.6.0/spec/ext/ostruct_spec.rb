# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AmazingPrint Ostruct extension' do
  before do
    @ap = AmazingPrint::Inspector.new(plain: true, sort_keys: true)
  end

  it 'empty hash' do
    struct = OpenStruct.new
    expect(@ap.send(:awesome, struct)).to eq('OpenStruct {}')
  end

  it 'plain multiline' do
    struct = OpenStruct.new name: 'Foo', address: 'Bar'
    expect(@ap.send(:awesome, struct)).to eq <<~EOS.strip
      OpenStruct {
          :address => "Bar",
             :name => "Foo"
      }
    EOS
  end
end

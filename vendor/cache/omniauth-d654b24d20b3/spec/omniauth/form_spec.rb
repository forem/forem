require 'helper'

describe OmniAuth::Form do
  describe '.build' do
    it 'yields the instance when called with a block and argument' do
      OmniAuth::Form.build { |f| expect(f).to be_kind_of(OmniAuth::Form) }
    end

    it 'evaluates in the instance when called with a block and no argument' do
      OmniAuth::Form.build { |f| expect(f.class).to eq(OmniAuth::Form) }
    end
  end

  describe '#initialize' do
    it 'sets the form action to the passed :url option' do
      expect(OmniAuth::Form.new(:url => '/awesome').to_html).to be_include("action='/awesome'")
    end

    it 'sets an H1 tag from the passed :title option' do
      expect(OmniAuth::Form.new(:title => 'Something Cool').to_html).to be_include('<h1>Something Cool</h1>')
    end
  end
end

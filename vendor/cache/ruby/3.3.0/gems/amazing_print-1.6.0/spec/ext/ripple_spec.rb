# frozen_string_literal: true

# rubocop:disable Lint/ConstantDefinitionInBlock

require 'spec_helper'

RSpec.describe 'AmazingPrint/Ripple', skip: -> { !ExtVerifier.has_ripple? }.call do
  if ExtVerifier.has_ripple?
    before :all do
      class RippleUser
        include Ripple::Document

        key_on :_id
        property :_id, String
        property :first_name, String
        property :last_name,  String
      end
    end

    after :all do
      Object.instance_eval { remove_const :RippleUser }
    end
  end

  before do
    @ap = AmazingPrint::Inspector.new plain: true, sort_keys: true
  end

  it 'prints class instance' do
    user = RippleUser.new _id: '12345', first_name: 'Al', last_name: 'Capone'
    out = @ap.send :awesome, user

    expect(out).to be_similar_to <<~EOS.strip
      #<RippleUser:placeholder_id> {
                 :_id => "12345",
          :first_name => "Al",
           :last_name => "Capone"
      }
    EOS
  end

  it 'prints the class' do
    expect(@ap.send(:awesome, RippleUser)).to eq <<~EOS.strip
      class RippleUser < Object {
                 :_id => :string,
          :first_name => :string,
           :last_name => :string
      }
    EOS
  end
end

# rubocop:enable Lint/ConstantDefinitionInBlock

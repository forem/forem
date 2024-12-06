# frozen_string_literal: true

require 'spec_helper'
require 'sequel_helper'

RSpec.describe 'AmazingPrint/Sequel', skip: -> { !ExtVerifier.has_sequel? }.call do
  before do
    @ap = AmazingPrint::Inspector.new plain: true, sort_keys: true
    @user1 = SequelUser.new first_name: 'Jeremy', last_name: 'Evans'
    @user2 = SequelUser.new first_name: 'Sequel', last_name: 'Five'
  end

  it 'display single record' do
    out = @ap.awesome(@user1)
    str = <<~EOS.strip
      #<SequelUser:placeholder_id> {
          :first_name => "Jeremy",
           :last_name => "Evans"
      }
    EOS
    expect(out).to be_similar_to(str)
  end

  it 'display multiple records' do
    out = @ap.awesome([@user1, @user2])
    str = <<~EOS.strip
      [
          [0] #<SequelUser:placeholder_id> {
              :first_name => "Jeremy",
               :last_name => "Evans"
          },
          [1] #<SequelUser:placeholder_id> {
              :first_name => "Sequel",
               :last_name => "Five"
          }
      ]
    EOS
    expect(out).to be_similar_to(str)
  end

  it 'does not crash if on Sequel::Model' do
    out = @ap.awesome(Sequel::Model)
    expect(out).to be_similar_to('Sequel::Model < Object')
  end
end

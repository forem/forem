# frozen_string_literal: true

require 'spec_helper'
require 'active_record_helper'

RSpec.describe 'ActiveModel::Errors formatting', skip: -> { !ExtVerifier.has_rails? }.call do
  before do
    @ap = AmazingPrint::Inspector.new(plain: true)
  end

  it 'formats active_model_errors properly' do
    model = TableFreeModel.new
    model.errors.add(:name, "can't be blank")

    out = @ap.awesome(model.errors)

    str = <<~ERRORS.strip
      #<ActiveModel::Errors:placeholder_id> {
             "name" => nil,
           :details => {
              :name => [
                  [0] {
                      :error => "can't be blank"
                  }
              ]
          },
          :messages => {
              :name => [
                  [0] "can't be blank"
              ]
          }
      }
    ERRORS

    expect(out).to be_similar_to(str)
  end
end

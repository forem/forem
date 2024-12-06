# frozen_string_literal: true

require 'spec_helper'

module TransactionSpec
  class MockModel
    include Modis::Model
  end
end

describe Modis::Transaction do
  it 'yields the block in a transaction' do
    redis = double.as_null_object
    allow(Modis).to receive(:with_connection).and_yield(redis)
    expect(redis).to receive(:multi)
    TransactionSpec::MockModel.transaction {}
  end
end

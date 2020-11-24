# frozen_string_literal: true

require 'spec_helper'

module Bullet
  module Registry
    describe Association do
      subject { Association.new.tap { |association| association.add(%w[key1 key2], 'value') } }

      context '#merge' do
        it 'should merge key/value' do
          subject.merge('key0', 'value0')
          expect(subject['key0']).to be_include('value0')
        end
      end

      context '#similarly_associated' do
        it 'should return similarly associated keys' do
          expect(subject.similarly_associated('key1', Set.new(%w[value]))).to eq(%w[key1 key2])
        end

        it 'should return empty if key does not exist' do
          expect(subject.similarly_associated('key3', Set.new(%w[value]))).to be_empty
        end
      end
    end
  end
end

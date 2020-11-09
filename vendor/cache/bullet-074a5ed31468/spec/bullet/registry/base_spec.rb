# frozen_string_literal: true

require 'spec_helper'

module Bullet
  module Registry
    describe Base do
      subject { Base.new.tap { |base| base.add('key', 'value') } }

      context '#[]' do
        it 'should get value by key' do
          expect(subject['key']).to eq(Set.new(%w[value]))
        end
      end

      context '#delete' do
        it 'should delete key' do
          subject.delete('key')
          expect(subject['key']).to be_nil
        end
      end

      context '#add' do
        it 'should add value with string' do
          subject.add('key', 'new_value')
          expect(subject['key']).to eq(Set.new(%w[value new_value]))
        end

        it 'should add value with array' do
          subject.add('key', %w[value1 value2])
          expect(subject['key']).to eq(Set.new(%w[value value1 value2]))
        end
      end

      context '#include?' do
        it 'should include key/value' do
          expect(subject.include?('key', 'value')).to eq true
        end

        it 'should not include wrong key/value' do
          expect(subject.include?('key', 'val')).to eq false
        end
      end
    end
  end
end

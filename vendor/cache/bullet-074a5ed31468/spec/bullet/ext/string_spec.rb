# frozen_string_literal: true

require 'spec_helper'

describe String do
  context 'bullet_class_name' do
    it 'should only return class name' do
      expect('Post:1'.bullet_class_name).to eq('Post')
    end

    it 'should return class name with namespace' do
      expect('Mongoid::Post:1234567890'.bullet_class_name).to eq('Mongoid::Post')
    end
  end
end

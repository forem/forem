# frozen_string_literal: true

require 'spec_helper'

module Bullet
  module Detector
    describe Association do
      before :all do
        @post1 = Post.first
        @post2 = Post.last
      end

      context '.add_object_association' do
        it 'should add object, associations pair' do
          Association.add_object_associations(@post1, :associations)
          expect(Association.send(:object_associations)).to be_include(@post1.bullet_key, :associations)
        end
      end

      context '.add_call_object_associations' do
        it 'should add call object, associations pair' do
          Association.add_call_object_associations(@post1, :associations)
          expect(Association.send(:call_object_associations)).to be_include(@post1.bullet_key, :associations)
        end
      end
    end
  end
end

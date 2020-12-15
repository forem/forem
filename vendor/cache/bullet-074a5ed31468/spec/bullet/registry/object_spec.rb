# frozen_string_literal: true

require 'spec_helper'

module Bullet
  module Registry
    describe Object do
      let(:post) { Post.first }
      let(:another_post) { Post.last }
      subject { Object.new.tap { |object| object.add(post.bullet_key) } }

      context '#include?' do
        it 'should include the object' do
          expect(subject).to be_include(post.bullet_key)
        end
      end

      context '#add' do
        it 'should add an object' do
          subject.add(another_post.bullet_key)
          expect(subject).to be_include(another_post.bullet_key)
        end
      end
    end
  end
end

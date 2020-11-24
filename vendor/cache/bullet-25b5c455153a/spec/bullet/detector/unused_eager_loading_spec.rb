# frozen_string_literal: true

require 'spec_helper'

module Bullet
  module Detector
    describe UnusedEagerLoading do
      before(:all) do
        @post = Post.first
        @post2 = Post.all[1]
        @post3 = Post.last
      end

      context '.call_associations' do
        it 'should get empty array if eager_loadings' do
          expect(UnusedEagerLoading.send(:call_associations, @post.bullet_key, Set.new([:association]))).to be_empty
        end

        it 'should get call associations if object and association are both in eager_loadings and call_object_associations' do
          UnusedEagerLoading.add_eager_loadings([@post], :association)
          UnusedEagerLoading.add_call_object_associations(@post, :association)
          expect(UnusedEagerLoading.send(:call_associations, @post.bullet_key, Set.new([:association]))).to eq([:association])
        end

        it 'should not get call associations if not exist in call_object_associations' do
          UnusedEagerLoading.add_eager_loadings([@post], :association)
          expect(UnusedEagerLoading.send(:call_associations, @post.bullet_key, Set.new([:association]))).to be_empty
        end
      end

      context '.diff_object_associations' do
        it 'should return associations not exist in call_association' do
          expect(UnusedEagerLoading.send(:diff_object_associations, @post.bullet_key, Set.new([:association]))).to eq([:association])
        end

        it 'should return empty if associations exist in call_association' do
          UnusedEagerLoading.add_eager_loadings([@post], :association)
          UnusedEagerLoading.add_call_object_associations(@post, :association)
          expect(
            UnusedEagerLoading.send(:diff_object_associations, @post.bullet_key, Set.new([:association]))
          ).to be_empty
        end
      end

      context '.check_unused_preload_associations' do
        let(:paths) { %w[/dir1 /dir1/subdir] }
        it 'should create notification if object_association_diff is not empty' do
          UnusedEagerLoading.add_object_associations(@post, :association)
          allow(UnusedEagerLoading).to receive(:caller_in_project).and_return(paths)
          expect(UnusedEagerLoading).to receive(:create_notification).with(paths, 'Post', [:association])
          UnusedEagerLoading.check_unused_preload_associations
        end

        it 'should not create notification if object_association_diff is empty' do
          UnusedEagerLoading.add_object_associations(@post, :association)
          UnusedEagerLoading.add_eager_loadings([@post], :association)
          UnusedEagerLoading.add_call_object_associations(@post, :association)
          expect(
            UnusedEagerLoading.send(:diff_object_associations, @post.bullet_key, Set.new([:association]))
          ).to be_empty
          expect(UnusedEagerLoading).not_to receive(:create_notification).with('Post', [:association])
          UnusedEagerLoading.check_unused_preload_associations
        end
      end

      context '.add_eager_loadings' do
        it 'should add objects, associations pair when eager_loadings are empty' do
          UnusedEagerLoading.add_eager_loadings([@post, @post2], :associations)
          expect(UnusedEagerLoading.send(:eager_loadings)).to be_include(
            [@post.bullet_key, @post2.bullet_key],
            :associations
          )
        end

        it 'should add objects, associations pair for existing eager_loadings' do
          UnusedEagerLoading.add_eager_loadings([@post, @post2], :association1)
          UnusedEagerLoading.add_eager_loadings([@post, @post2], :association2)
          expect(UnusedEagerLoading.send(:eager_loadings)).to be_include(
            [@post.bullet_key, @post2.bullet_key],
            :association1
          )
          expect(UnusedEagerLoading.send(:eager_loadings)).to be_include(
            [@post.bullet_key, @post2.bullet_key],
            :association2
          )
        end

        it 'should merge objects, associations pair for existing eager_loadings' do
          UnusedEagerLoading.add_eager_loadings([@post], :association1)
          UnusedEagerLoading.add_eager_loadings([@post, @post2], :association2)
          expect(UnusedEagerLoading.send(:eager_loadings)).to be_include([@post.bullet_key], :association1)
          expect(UnusedEagerLoading.send(:eager_loadings)).to be_include([@post.bullet_key], :association2)
          expect(UnusedEagerLoading.send(:eager_loadings)).to be_include([@post2.bullet_key], :association2)
        end

        it 'should vmerge objects recursively, associations pair for existing eager_loadings' do
          UnusedEagerLoading.add_eager_loadings([@post, @post2], :association1)
          UnusedEagerLoading.add_eager_loadings([@post, @post3], :association1)
          UnusedEagerLoading.add_eager_loadings([@post, @post3], :association2)
          expect(UnusedEagerLoading.send(:eager_loadings)).to be_include([@post.bullet_key], :association1)
          expect(UnusedEagerLoading.send(:eager_loadings)).to be_include([@post.bullet_key], :association2)
          expect(UnusedEagerLoading.send(:eager_loadings)).to be_include([@post2.bullet_key], :association1)
          expect(UnusedEagerLoading.send(:eager_loadings)).to be_include([@post3.bullet_key], :association1)
          expect(UnusedEagerLoading.send(:eager_loadings)).to be_include([@post3.bullet_key], :association2)
        end

        it 'should delete objects, associations pair for existing eager_loadings' do
          UnusedEagerLoading.add_eager_loadings([@post, @post2], :association1)
          UnusedEagerLoading.add_eager_loadings([@post], :association2)
          expect(UnusedEagerLoading.send(:eager_loadings)).to be_include([@post.bullet_key], :association1)
          expect(UnusedEagerLoading.send(:eager_loadings)).to be_include([@post.bullet_key], :association2)
          expect(UnusedEagerLoading.send(:eager_loadings)).to be_include([@post2.bullet_key], :association1)
        end
      end
    end
  end
end

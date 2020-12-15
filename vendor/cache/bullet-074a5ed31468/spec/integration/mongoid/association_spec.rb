# frozen_string_literal: true

require 'spec_helper'

if mongoid?
  describe Bullet::Detector::Association do
    context 'embeds_many' do
      context 'posts => users' do
        it 'should detect nothing' do
          Mongoid::Post.all.each { |post| post.users.map(&:name) }
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end
      end
    end

    context 'has_many' do
      context 'posts => comments' do
        it 'should detect non preload posts => comments' do
          Mongoid::Post.all.each { |post| post.comments.map(&:name) }
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Mongoid::Post, :comments)
        end

        it 'should detect preload post => comments' do
          Mongoid::Post.includes(:comments).each { |post| post.comments.map(&:name) }
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end

        it 'should detect unused preload post => comments' do
          Mongoid::Post.includes(:comments).map(&:name)
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Mongoid::Post, :comments)

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end

        it 'should not detect unused preload post => comments' do
          Mongoid::Post.all.map(&:name)
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end
      end

      context 'category => posts, category => entries' do
        it 'should detect non preload with category => [posts, entries]' do
          Mongoid::Category.all.each do |category|
            category.posts.map(&:name)
            category.entries.map(&:name)
          end
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Mongoid::Category, :posts)
          expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Mongoid::Category, :entries)
        end

        it 'should detect preload with category => posts, but not with category => entries' do
          Mongoid::Category.includes(:posts).each do |category|
            category.posts.map(&:name)
            category.entries.map(&:name)
          end
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).not_to be_detecting_unpreloaded_association_for(
            Mongoid::Category,
            :posts
          )
          expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Mongoid::Category, :entries)
        end

        it 'should detect preload with category => [posts, entries]' do
          Mongoid::Category.includes(:posts, :entries).each do |category|
            category.posts.map(&:name)
            category.entries.map(&:name)
          end
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end

        it 'should detect unused preload with category => [posts, entries]' do
          Mongoid::Category.includes(:posts, :entries).map(&:name)
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Mongoid::Category, :posts)
          expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Mongoid::Category, :entries)

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end

        it 'should detect unused preload with category => entries, but not with category => posts' do
          Mongoid::Category.includes(:posts, :entries).each { |category| category.posts.map(&:name) }
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_unused_preload_associations_for(Mongoid::Category, :posts)
          expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Mongoid::Category, :entries)

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end
      end

      context 'post => comment' do
        it 'should detect unused preload with post => comments' do
          Mongoid::Post.includes(:comments).each { |post| post.comments.first.name }
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_unused_preload_associations_for(Mongoid::Post, :comments)

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end

        it 'should detect preload with post => commnets' do
          Mongoid::Post.first.comments.map(&:name)
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end
      end

      context 'scope preload_comments' do
        it 'should detect preload post => comments with scope' do
          Mongoid::Post.preload_comments.each { |post| post.comments.map(&:name) }
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end

        it 'should detect unused preload with scope' do
          Mongoid::Post.preload_comments.map(&:name)
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Mongoid::Post, :comments)

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end
      end
    end

    context 'belongs_to' do
      context 'comment => post' do
        it 'should detect non preload with comment => post' do
          Mongoid::Comment.all.each { |comment| comment.post.name }
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Mongoid::Comment, :post)
        end

        it 'should detect preload with one comment => post' do
          Mongoid::Comment.first.post.name
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end

        it 'should detect preload with comment => post' do
          Mongoid::Comment.includes(:post).each { |comment| comment.post.name }
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end

        it 'should not detect preload with comment => post' do
          Mongoid::Comment.all.map(&:name)
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end

        it 'should detect unused preload with comments => post' do
          Mongoid::Comment.includes(:post).map(&:name)
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Mongoid::Comment, :post)

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end
      end
    end

    context 'has_one' do
      context 'company => address' do
        if Mongoid::VERSION !~ /\A3.0/
          it 'should detect non preload association' do
            Mongoid::Company.all.each { |company| company.address.name }
            Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
            expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

            expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(
              Mongoid::Company,
              :address
            )
          end
        end

        it 'should detect preload association' do
          Mongoid::Company.includes(:address).each { |company| company.address.name }
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end

        it 'should not detect preload association' do
          Mongoid::Company.all.map(&:name)
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end

        it 'should detect unused preload association' do
          criteria = Mongoid::Company.includes(:address)
          criteria.map(&:name)
          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Mongoid::Company, :address)

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end
      end
    end

    context 'call one association that in possible objects' do
      it 'should not detect preload association' do
        Mongoid::Post.all
        Mongoid::Post.first.comments.map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

if active_record?
  describe Bullet::Detector::Association, 'has_many' do
    context 'post => comments' do
      it 'should detect non preload post => comments' do
        Post.all.each { |post| post.comments.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Post, :comments)
      end

      it 'should detect non preload post => comments for find_by_sql' do
        Post.find_by_sql('SELECT * FROM posts').each { |post| post.comments.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Post, :comments)
      end

      it 'should detect preload with post => comments' do
        Post.includes(:comments).each { |post| post.comments.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect unused preload post => comments' do
        Post.includes(:comments).map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Post, :comments)

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should not detect unused preload post => comments' do
        Post.all.map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect non preload comment => post with inverse_of' do
        Post.includes(:comments).each do |post|
          post.comments.each do |comment|
            comment.name
            comment.post.name
          end
        end
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect non preload post => comments with empty?' do
        Post.all.each { |post| post.comments.empty? }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Post, :comments)
      end

      it 'should detect non preload post => comments with include?' do
        comment = Comment.last
        Post.all.each { |post| post.comments.include?(comment) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Post, :comments)
      end

      it 'should not detect unused preload person => pets with empty?' do
        Person.all.each { |person| person.pets.empty? }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end
    end

    context 'category => posts => comments' do
      it 'should detect non preload category => posts => comments' do
        Category.all.each { |category| category.posts.each { |post| post.comments.map(&:name) } }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Category, :posts)
        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Post, :comments)
      end

      it 'should detect preload category => posts, but no post => comments' do
        Category.includes(:posts).each { |category| category.posts.each { |post| post.comments.map(&:name) } }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).not_to be_detecting_unpreloaded_association_for(Category, :posts)
        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Post, :comments)
      end

      it 'should detect preload with category => posts => comments' do
        Category.includes(posts: :comments).each { |category| category.posts.each { |post| post.comments.map(&:name) } }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect preload with category => posts => comments with posts.id > 0' do
        Category.includes(posts: :comments).where('posts.id > 0').references(:posts).each do |category|
          category.posts.each { |post| post.comments.map(&:name) }
        end
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect unused preload with category => posts => comments' do
        Category.includes(posts: :comments).map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Post, :comments)

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect unused preload with post => commnets, no category => posts' do
        Category.includes(posts: :comments).each { |category| category.posts.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Post, :comments)

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end
    end

    context 'category => posts, category => entries' do
      it 'should detect non preload with category => [posts, entries]' do
        Category.all.each do |category|
          category.posts.map(&:name)
          category.entries.map(&:name)
        end
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Category, :posts)
        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Category, :entries)
      end

      it 'should detect preload with category => posts, but not with category => entries' do
        Category.includes(:posts).each do |category|
          category.posts.map(&:name)
          category.entries.map(&:name)
        end
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).not_to be_detecting_unpreloaded_association_for(Category, :posts)
        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Category, :entries)
      end

      it 'should detect preload with category => [posts, entries]' do
        Category.includes(%i[posts entries]).each do |category|
          category.posts.map(&:name)
          category.entries.map(&:name)
        end
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect unused preload with category => [posts, entries]' do
        Category.includes(%i[posts entries]).map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Category, :posts)
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Category, :entries)

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect unused preload with category => entries, but not with category => posts' do
        Category.includes(%i[posts entries]).each { |category| category.posts.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_unused_preload_associations_for(Category, :posts)
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Category, :entries)

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end
    end

    context 'post => comment' do
      it 'should detect unused preload with post => comments' do
        Post.includes(:comments).each { |post| post.comments.first&.name }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_unused_preload_associations_for(Post, :comments)

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect preload with post => commnets' do
        Post.first.comments.map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should not detect unused preload with category => posts' do
        category = Category.first
        category.draft_post.destroy!
        post = category.draft_post
        post.update!(link: true)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations

        Support::SqliteSeed.setup_db
        Support::SqliteSeed.seed_db
      end
    end

    context 'category => posts => writer' do
      it 'should not detect unused preload associations' do
        category = Category.includes(posts: :writer).order('id DESC').find_by_name('first')
        category.posts.map do |post|
          post.name
          post.writer.name
        end
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_unused_preload_associations_for(Category, :posts)
        expect(Bullet::Detector::Association).not_to be_unused_preload_associations_for(Post, :writer)
      end
    end

    context 'scope for_category_name' do
      it 'should detect preload with post => category' do
        Post.in_category_name('first').references(:categories).each { |post| post.category.name }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should not be unused preload post => category' do
        Post.in_category_name('first').references(:categories).map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end
    end

    context 'scope preload_comments' do
      it 'should detect preload post => comments with scope' do
        Post.preload_comments.each { |post| post.comments.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect unused preload with scope' do
        Post.preload_comments.map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Post, :comments)

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end
    end
  end

  describe Bullet::Detector::Association, 'belongs_to' do
    context 'comment => post' do
      it 'should detect non preload with comment => post' do
        Comment.all.each { |comment| comment.post.name }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Comment, :post)
      end

      it 'should detect preload with one comment => post' do
        Comment.first.post.name
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect preload with comment => post' do
        Comment.includes(:post).each { |comment| comment.post.name }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should not detect preload with comment => post' do
        Comment.all.map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect unused preload with comment => post' do
        Comment.includes(:post).map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Comment, :post)

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should not detect newly assigned object in an after_save' do
        new_post = Post.new(category: Category.first)

        new_post.trigger_after_save = true
        new_post.save!
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end
    end

    context 'comment => post => category' do
      it 'should detect non preload association with comment => post' do
        Comment.all.each { |comment| comment.post.category.name }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Comment, :post)
      end

      it 'should not detect non preload association with only one comment' do
        Comment.first.post.category.name

        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect non preload association with post => category' do
        Comment.includes(:post).each { |comment| comment.post.category.name }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Post, :category)
      end

      it 'should not detect unpreload association' do
        Comment.includes(post: :category).each { |comment| comment.post.category.name }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end
    end

    context 'comment => author, post => writer' do
      it 'should detect non preloaded writer' do
        Comment.includes(%i[author post]).where(['base_users.id = ?', BaseUser.first]).references(:base_users)
          .each { |comment| comment.post.writer.name }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Post, :writer)
      end

      it 'should detect unused preload with comment => author' do
        Comment.includes([:author, { post: :writer }]).where(['base_users.id = ?', BaseUser.first]).references(
          :base_users
        ).each { |comment| comment.post.writer.name }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect non preloading with writer => newspaper' do
        Comment.includes(post: :writer).where("posts.name like '%first%'").references(:posts).each do |comment|
          comment.post.writer.newspaper.name
        end
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Writer, :newspaper)
      end

      it 'should not raise a stack error from posts to category' do
        expect { Comment.includes(post: :category).each { |com| com.post.category } }.not_to raise_error
      end
    end
  end

  describe Bullet::Detector::Association, 'has_and_belongs_to_many' do
    context 'students <=> teachers' do
      it 'should detect non preload associations' do
        Student.all.each { |student| student.teachers.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Student, :teachers)
      end

      it 'should detect preload associations' do
        Student.includes(:teachers).each { |student| student.teachers.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect unused preload associations' do
        Student.includes(:teachers).map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Student, :teachers)

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect no unused preload associations' do
        Student.all.map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect non preload student => teachers with empty?' do
        Student.all.each { |student| student.teachers.empty? }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Student, :teachers)
      end
    end
  end

  describe Bullet::Detector::Association, 'has_many :through' do
    context 'firm => clients' do
      it 'should detect non preload associations' do
        Firm.all.each { |firm| firm.clients.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Firm, :clients)
      end

      it 'should detect preload associations' do
        Firm.includes(:clients).each { |firm| firm.clients.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should not detect preload associations' do
        Firm.all.map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect unused preload associations' do
        Firm.includes(:clients).map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Firm, :clients)

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end
    end

    context 'firm => clients => groups' do
      it 'should detect non preload associations' do
        Firm.all.each { |firm| firm.groups.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Firm, :groups)
      end

      it 'should detect preload associations' do
        Firm.includes(:groups).each { |firm| firm.groups.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should not detect preload associations' do
        Firm.all.map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect unused preload associations' do
        Firm.includes(:groups).map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Firm, :groups)

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end
    end
  end

  describe Bullet::Detector::Association, 'has_one' do
    context 'company => address' do
      it 'should detect non preload association' do
        Company.all.each { |company| company.address.name }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Company, :address)
      end

      it 'should detect preload association' do
        Company.includes(:address).each { |company| company.address.name }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should not detect preload association' do
        Company.all.map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect unused preload association' do
        Company.includes(:address).map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Company, :address)

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end
    end
  end

  describe Bullet::Detector::Association, 'has_one => has_many' do
    it 'should not detect preload association' do
      user = User.first
      user.submission.replies.map(&:name)
      Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
      expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

      expect(Bullet::Detector::Association).to be_completely_preloading_associations
    end
  end

  describe Bullet::Detector::Association, 'call one association that in possible objects' do
    it 'should not detect preload association' do
      Post.all
      Post.first.comments.map(&:name)
      Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
      expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

      expect(Bullet::Detector::Association).to be_completely_preloading_associations
    end
  end

  describe Bullet::Detector::Association, 'query immediately after creation' do
    context 'with save' do
      context 'document => children' do
        it 'should not detect non preload associations' do
          document1 = Document.new
          document1.children.build
          document1.save

          document2 = Document.new(parent: document1)
          document2.save
          document2.parent

          document1.children.each.first

          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end
      end
    end

    context 'with save!' do
      context 'document => children' do
        it 'should not detect non preload associations' do
          document1 = Document.new
          document1.children.build
          document1.save!

          document2 = Document.new(parent: document1)
          document2.save!
          document2.parent

          document1.children.each.first

          Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
          expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

          expect(Bullet::Detector::Association).to be_completely_preloading_associations
        end
      end
    end
  end

  describe Bullet::Detector::Association, 'STI' do
    context 'page => author' do
      it 'should detect non preload associations' do
        Page.all.each { |page| page.author.name }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Page, :author)
      end

      it 'should detect preload associations' do
        Page.includes(:author).each { |page| page.author.name }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should detect unused preload associations' do
        Page.includes(:author).map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Page, :author)

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end

      it 'should not detect preload associations' do
        Page.all.map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
      end
    end

    context 'disable n plus one query' do
      before { Bullet.n_plus_one_query_enable = false }
      after { Bullet.n_plus_one_query_enable = true }

      it 'should not detect n plus one query' do
        Post.all.each { |post| post.comments.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations

        expect(Bullet::Detector::Association).not_to be_detecting_unpreloaded_association_for(Post, :comments)
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations
      end

      it 'should still detect unused eager loading' do
        Post.includes(:comments).map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Post, :comments)
      end
    end

    context 'disable unused eager loading' do
      before { Bullet.unused_eager_loading_enable = false }
      after { Bullet.unused_eager_loading_enable = true }

      it 'should not detect unused eager loading' do
        Post.includes(:comments).map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations
      end

      it 'should still detect n plus one query' do
        Post.all.each { |post| post.comments.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Post, :comments)
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations
      end
    end

    context 'whitelist n plus one query' do
      before { Bullet.add_whitelist type: :n_plus_one_query, class_name: 'Post', association: :comments }
      after { Bullet.clear_whitelist }

      it 'should not detect n plus one query' do
        Post.all.each { |post| post.comments.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations

        expect(Bullet::Detector::Association).not_to be_detecting_unpreloaded_association_for(Post, :comments)
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations
      end

      it 'should still detect unused eager loading' do
        Post.includes(:comments).map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
        expect(Bullet::Detector::Association).to be_unused_preload_associations_for(Post, :comments)
      end
    end

    context 'whitelist unused eager loading' do
      before { Bullet.add_whitelist type: :unused_eager_loading, class_name: 'Post', association: :comments }
      after { Bullet.clear_whitelist }

      it 'should not detect unused eager loading' do
        Post.includes(:comments).map(&:name)
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations

        expect(Bullet::Detector::Association).to be_completely_preloading_associations
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations
      end

      it 'should still detect n plus one query' do
        Post.all.each { |post| post.comments.map(&:name) }
        Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations

        expect(Bullet::Detector::Association).to be_detecting_unpreloaded_association_for(Post, :comments)
        expect(Bullet::Detector::Association).not_to be_has_unused_preload_associations
      end
    end
  end
end

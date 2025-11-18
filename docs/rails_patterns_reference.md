# Rails Patterns Quick Reference for Forem

This document provides quick reference examples of common Rails patterns used throughout the Forem codebase.

## Model Patterns

### Basic Model Structure
```ruby
class Article < ApplicationRecord
  # Associations first
  belongs_to :user
  belongs_to :organization, optional: true
  has_many :comments, dependent: :destroy
  has_many :reactions, as: :reactable, dependent: :destroy

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :body_markdown, presence: true
  validates :user_id, presence: true

  # Scopes
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }

  # Enums
  enum status: { draft: 0, published: 1, archived: 2 }

  # Callbacks
  before_save :generate_slug
  after_create :notify_followers

  # Instance methods
  def reading_time
    (body_markdown.split.length / 200.0).ceil
  end

  def published?
    published_at.present?
  end

  private

  def generate_slug
    self.slug = title.parameterize if title_changed?
  end

  def notify_followers
    NotificationWorker.perform_async(id) if published?
  end
end
```

### Advanced Model Patterns

#### Concerns and Modules
```ruby
# app/models/concerns/reactable.rb
module Reactable
  extend ActiveSupport::Concern

  included do
    has_many :reactions, as: :reactable, dependent: :destroy
    has_many :positive_reactions, -> { where(category: 'like') }, 
             as: :reactable, class_name: 'Reaction'
  end

  def reaction_count
    reactions.count
  end

  def positive_reaction_count
    positive_reactions.count
  end
end

# Usage in model
class Article < ApplicationRecord
  include Reactable
  # ... other code
end
```

#### Custom Validators
```ruby
# app/validators/slug_validator.rb
class SlugValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    unless value.match?(/\A[a-z0-9\-]+\z/)
      record.errors.add(attribute, 'must contain only lowercase letters, numbers, and hyphens')
    end

    if value.length < 3
      record.errors.add(attribute, 'must be at least 3 characters long')
    end
  end
end

# Usage in model
class Article < ApplicationRecord
  validates :slug, slug: true, uniqueness: true
end
```

#### Complex Scopes and Query Objects
```ruby
# app/models/article.rb
class Article < ApplicationRecord
  scope :with_minimum_score, ->(score = 0) { where('score >= ?', score) }
  scope :published_in_timeframe, ->(timeframe) { published.where(published_at: timeframe) }
  
  # Complex scope with joins
  scope :with_positive_reactions, -> do
    joins(:reactions)
      .where(reactions: { category: 'like' })
      .group('articles.id')
      .having('COUNT(reactions.id) > 0')
  end

  # Class methods for complex queries
  def self.popular_in_timeframe(timeframe = 1.week.ago)
    published
      .where(published_at: timeframe..)
      .joins(:reactions)
      .group('articles.id')
      .order('COUNT(reactions.id) DESC')
      .limit(10)
  end
end
```

## Controller Patterns

### Standard RESTful Controller
```ruby
class ArticlesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_article, only: [:show, :edit, :update, :destroy]
  before_action :authorize_article!, only: [:edit, :update, :destroy]

  def index
    @articles = Article.published
                      .includes(:user, :tags)
                      .page(params[:page])
                      .per(25)
  end

  def show
    @comment = Comment.new
    @related_articles = RelatedArticlesQuery.new(@article).call.limit(3)
  end

  def new
    @article = current_user.articles.build
  end

  def create
    @article = current_user.articles.build(article_params)
    
    if @article.save
      redirect_to @article, notice: 'Article was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @article.update(article_params)
      redirect_to @article, notice: 'Article was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    redirect_to articles_url, notice: 'Article was successfully deleted.'
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def authorize_article!
    redirect_to root_path unless current_user.can_edit?(@article)
  end

  def article_params
    params.require(:article).permit(:title, :body_markdown, :published, tag_list: [])
  end
end
```

### API Controller Pattern
```ruby
class Api::V1::ArticlesController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_article, only: [:show, :update, :destroy]

  def index
    @articles = Article.published
                      .includes(:user, :organization)
                      .page(params[:page])
                      .per(params[:per_page] || 30)

    render json: @articles, each_serializer: ArticleSerializer
  end

  def show
    render json: @article, serializer: ArticleSerializer
  end

  def create
    @article = current_user.articles.build(article_params)

    if @article.save
      render json: @article, serializer: ArticleSerializer, status: :created
    else
      render json: { errors: @article.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @article.update(article_params)
      render json: @article, serializer: ArticleSerializer
    else
      render json: { errors: @article.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    head :no_content
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def article_params
    params.require(:article).permit(:title, :body_markdown, :published, tag_list: [])
  end
end
```

### Nested Resource Controller
```ruby
class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_article
  before_action :set_comment, only: [:show, :edit, :update, :destroy]

  def index
    @comments = @article.comments.includes(:user).order(:created_at)
  end

  def create
    @comment = @article.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to @article, notice: 'Comment was successfully created.'
    else
      redirect_to @article, alert: 'Error creating comment.'
    end
  end

  def update
    if @comment.update(comment_params)
      redirect_to @article, notice: 'Comment was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    redirect_to @article, notice: 'Comment was successfully deleted.'
  end

  private

  def set_article
    @article = Article.find(params[:article_id])
  end

  def set_comment
    @comment = @article.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body_markdown)
  end
end
```

## Service Object Patterns

### Basic Service Object
```ruby
# app/services/article_publisher.rb
class ArticlePublisher
  def initialize(article, user)
    @article = article
    @user = user
  end

  def call
    return false unless can_publish?

    ActiveRecord::Base.transaction do
      publish_article
      send_notifications
      update_user_stats
    end

    true
  rescue StandardError => e
    Rails.logger.error "Failed to publish article #{@article.id}: #{e.message}"
    false
  end

  private

  def can_publish?
    @user.can_publish?(@article) && @article.valid?
  end

  def publish_article
    @article.update!(
      published: true,
      published_at: Time.current,
      score: calculate_initial_score
    )
  end

  def send_notifications
    NotificationWorker.perform_async(@article.id, 'article_published')
  end

  def update_user_stats
    @user.increment!(:articles_count)
  end

  def calculate_initial_score
    # Complex scoring logic
    base_score = @user.reputation_score / 10
    content_score = @article.body_markdown.length / 100
    [base_score + content_score, 0].max
  end
end
```

### Service Object with Result Object
```ruby
# app/services/concerns/service_result.rb
class ServiceResult
  attr_reader :success, :data, :errors

  def initialize(success:, data: nil, errors: [])
    @success = success
    @data = data
    @errors = errors
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def self.success(data = nil)
    new(success: true, data: data)
  end

  def self.failure(errors)
    new(success: false, errors: Array(errors))
  end
end

# app/services/user_registration_service.rb
class UserRegistrationService
  def initialize(user_params)
    @user_params = user_params
  end

  def call
    user = User.new(@user_params)

    return ServiceResult.failure(user.errors.full_messages) unless user.valid?

    ActiveRecord::Base.transaction do
      user.save!
      send_welcome_email(user)
      create_default_settings(user)
    end

    ServiceResult.success(user)
  rescue StandardError => e
    Rails.logger.error "User registration failed: #{e.message}"
    ServiceResult.failure(['Registration failed. Please try again.'])
  end

  private

  def send_welcome_email(user)
    UserMailer.welcome_email(user).deliver_later
  end

  def create_default_settings(user)
    Users::Setting.create!(
      user: user,
      email_notifications: true,
      display_sponsors: true
    )
  end
end
```

## Query Object Patterns

### Basic Query Object
```ruby
# app/queries/popular_articles_query.rb
class PopularArticlesQuery
  def initialize(timeframe: 1.week.ago, limit: 10)
    @timeframe = timeframe
    @limit = limit
  end

  def call
    Article.published
           .where(published_at: @timeframe..)
           .joins(:reactions)
           .group('articles.id')
           .order('COUNT(reactions.id) DESC')
           .limit(@limit)
  end
end

# Usage in controller
class HomeController < ApplicationController
  def index
    @popular_articles = PopularArticlesQuery.new(timeframe: 1.month.ago).call
  end
end
```

### Complex Query Object with Parameters
```ruby
# app/queries/article_search_query.rb
class ArticleSearchQuery
  def initialize(params = {})
    @query = params[:q]
    @tags = params[:tags]
    @user_id = params[:user_id]
    @timeframe = params[:timeframe]
    @page = params[:page] || 1
    @per_page = params[:per_page] || 25
  end

  def call
    scope = Article.published.includes(:user, :tags)
    scope = filter_by_query(scope)
    scope = filter_by_tags(scope)
    scope = filter_by_user(scope)
    scope = filter_by_timeframe(scope)
    scope = order_results(scope)
    
    scope.page(@page).per(@per_page)
  end

  private

  def filter_by_query(scope)
    return scope if @query.blank?

    scope.where(
      'title ILIKE ? OR body_markdown ILIKE ?',
      "%#{@query}%", "%#{@query}%"
    )
  end

  def filter_by_tags(scope)
    return scope if @tags.blank?

    scope.tagged_with(@tags, any: true)
  end

  def filter_by_user(scope)
    return scope if @user_id.blank?

    scope.where(user_id: @user_id)
  end

  def filter_by_timeframe(scope)
    return scope if @timeframe.blank?

    case @timeframe
    when 'week'
      scope.where(published_at: 1.week.ago..)
    when 'month'
      scope.where(published_at: 1.month.ago..)
    when 'year'
      scope.where(published_at: 1.year.ago..)
    else
      scope
    end
  end

  def order_results(scope)
    scope.order(published_at: :desc)
  end
end
```

## Background Job Patterns

### Basic Sidekiq Worker
```ruby
# app/workers/notification_worker.rb
class NotificationWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3, backtrace: true

  def perform(article_id, notification_type)
    article = Article.find(article_id)
    
    case notification_type
    when 'article_published'
      send_publication_notifications(article)
    when 'article_featured'
      send_featured_notifications(article)
    else
      Rails.logger.warn "Unknown notification type: #{notification_type}"
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Article not found: #{article_id}"
  end

  private

  def send_publication_notifications(article)
    article.user.followers.find_each do |follower|
      NotificationMailer.new_article(follower, article).deliver_now
    end
  end

  def send_featured_notifications(article)
    User.where(featured_notifications: true).find_each do |user|
      NotificationMailer.featured_article(user, article).deliver_now
    end
  end
end
```

### Scheduled Job Pattern
```ruby
# app/workers/daily_digest_worker.rb
class DailyDigestWorker
  include Sidekiq::Worker
  include Sidekiq::Cron::Job

  sidekiq_options retry: 2

  def perform
    User.where(daily_digest: true).find_each do |user|
      DigestMailer.daily_digest(user).deliver_now
    end
  end
end

# Schedule in config/initializers/sidekiq.rb
Sidekiq::Cron::Job.create(
  name: 'Daily Digest',
  cron: '0 8 * * *', # 8 AM every day
  class: 'DailyDigestWorker'
)
```

## Serializer Patterns

### Basic Serializer
```ruby
# app/serializers/article_serializer.rb
class ArticleSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :body_html, :published_at, :slug, :url
  
  belongs_to :user, serializer: UserSerializer
  belongs_to :organization, serializer: OrganizationSerializer
  has_many :tags, serializer: TagSerializer

  def url
    Rails.application.routes.url_helpers.article_url(object)
  end

  def body_html
    object.processed_html
  end
end

# app/serializers/user_serializer.rb
class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :username, :profile_image_url

  def profile_image_url
    object.profile_image.present? ? object.profile_image : '/default-avatar.png'
  end
end
```

### Conditional Serializer
```ruby
# app/serializers/article_serializer.rb
class ArticleSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :published_at, :slug
  
  # Conditional attributes
  attribute :body_html, if: :show_body?
  attribute :edit_url, if: :can_edit?

  belongs_to :user, serializer: UserSerializer
  has_many :comments, serializer: CommentSerializer, if: :include_comments?

  def show_body?
    scope&.can_read_full_article?(object)
  end

  def can_edit?
    scope&.can_edit?(object)
  end

  def include_comments?
    instance_options[:include_comments] == true
  end

  def edit_url
    Rails.application.routes.url_helpers.edit_article_url(object)
  end
end
```

## Testing Patterns

### Model Testing
```ruby
# spec/models/article_spec.rb
RSpec.describe Article, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:organization).optional }
    it { should have_many(:comments).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(255) }
    it { should validate_presence_of(:body_markdown) }
  end

  describe 'scopes' do
    let!(:published_article) { create(:article, published: true) }
    let!(:draft_article) { create(:article, published: false) }

    describe '.published' do
      it 'returns only published articles' do
        expect(Article.published).to include(published_article)
        expect(Article.published).not_to include(draft_article)
      end
    end
  end

  describe '#reading_time' do
    it 'calculates reading time based on word count' do
      article = build(:article, body_markdown: 'word ' * 200)
      expect(article.reading_time).to eq(1)
    end

    it 'rounds up partial minutes' do
      article = build(:article, body_markdown: 'word ' * 250)
      expect(article.reading_time).to eq(2)
    end
  end
end
```

### Controller Testing
```ruby
# spec/controllers/articles_controller_spec.rb
RSpec.describe ArticlesController, type: :controller do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns published articles' do
      published_article = create(:article, published: true)
      draft_article = create(:article, published: false)
      
      get :index
      
      expect(assigns(:articles)).to include(published_article)
      expect(assigns(:articles)).not_to include(draft_article)
    end
  end

  describe 'POST #create' do
    context 'when user is signed in' do
      before { sign_in user }

      context 'with valid parameters' do
        let(:valid_attributes) do
          { title: 'Test Article', body_markdown: 'Test content' }
        end

        it 'creates a new article' do
          expect do
            post :create, params: { article: valid_attributes }
          end.to change(Article, :count).by(1)
        end

        it 'redirects to the created article' do
          post :create, params: { article: valid_attributes }
          expect(response).to redirect_to(Article.last)
        end
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) { { title: '', body_markdown: '' } }

        it 'does not create a new article' do
          expect do
            post :create, params: { article: invalid_attributes }
          end.not_to change(Article, :count)
        end

        it 'renders the new template' do
          post :create, params: { article: invalid_attributes }
          expect(response).to render_template(:new)
        end
      end
    end

    context 'when user is not signed in' do
      it 'redirects to sign in page' do
        post :create, params: { article: { title: 'Test' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
```

### Service Object Testing
```ruby
# spec/services/article_publisher_spec.rb
RSpec.describe ArticlePublisher do
  let(:user) { create(:user) }
  let(:article) { create(:article, :draft, user: user) }
  let(:service) { described_class.new(article, user) }

  describe '#call' do
    context 'when user can publish the article' do
      before do
        allow(user).to receive(:can_publish?).with(article).and_return(true)
      end

      it 'publishes the article' do
        expect { service.call }.to change { article.reload.published? }.to(true)
      end

      it 'sets the published_at timestamp' do
        service.call
        expect(article.reload.published_at).to be_present
      end

      it 'enqueues notification job' do
        expect(NotificationWorker).to receive(:perform_async).with(article.id, 'article_published')
        service.call
      end

      it 'returns true' do
        expect(service.call).to be true
      end
    end

    context 'when user cannot publish the article' do
      before do
        allow(user).to receive(:can_publish?).with(article).and_return(false)
      end

      it 'does not publish the article' do
        expect { service.call }.not_to change { article.reload.published? }
      end

      it 'returns false' do
        expect(service.call).to be false
      end
    end

    context 'when an error occurs' do
      before do
        allow(user).to receive(:can_publish?).with(article).and_return(true)
        allow(article).to receive(:update!).and_raise(StandardError, 'Database error')
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to publish article/)
        service.call
      end

      it 'returns false' do
        expect(service.call).to be false
      end
    end
  end
end
```

## Common Patterns Summary

### When to Use Each Pattern

#### Service Objects
- Complex business logic that doesn't belong in models or controllers
- Operations that involve multiple models
- External API integrations
- Background job coordination

#### Query Objects
- Complex database queries with multiple conditions
- Reusable query logic across controllers
- Search and filtering functionality
- Performance-critical queries

#### Concerns
- Shared behavior across multiple models
- Cross-cutting concerns like auditing or soft deletion
- Mixins for common functionality

#### Background Jobs
- Email sending
- External API calls
- Heavy computational tasks
- Scheduled operations

#### Serializers
- API response formatting
- Consistent data representation
- Conditional attribute inclusion
- Performance optimization for JSON responses

---

These patterns help maintain clean, testable, and maintainable code throughout the Forem application. Use them as guidelines and adapt them to specific use cases as needed.
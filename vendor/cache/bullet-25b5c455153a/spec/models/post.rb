# frozen_string_literal: true

class Post < ActiveRecord::Base
  belongs_to :category, inverse_of: :posts
  belongs_to :writer
  has_many :comments, inverse_of: :post

  validates :category, presence: true

  scope :preload_comments, -> { includes(:comments) }
  scope :in_category_name, ->(name) { where(['categories.name = ?', name]).includes(:category) }
  scope :draft, -> { where(active: false) }

  def link=(*)
    comments.new
  end

  # see association_spec.rb 'should not detect newly assigned object in an after_save'
  attr_accessor :trigger_after_save
  after_save do
    next unless trigger_after_save

    temp_comment = Comment.new(post: self)
    # this triggers self to be "possible", even though it's
    # not saved yet
    temp_comment.post

    # category should NOT whine about not being pre-loaded, because
    # it's obviously attached to a new object
    category
  end
end

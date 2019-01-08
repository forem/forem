class Block < ApplicationRecord
  attr_accessor :publish_now

  belongs_to :user

  validate :permissions

  before_save :process_html
  before_save :process_javascript
  before_save :process_css

  def publish!
    self.published_html = processed_html
    self.published_javascript = processed_javascript
    self.published_css = processed_css
    self.featured = true
    save
  end

  private

  def process_html
    self.processed_html = input_html
  end

  def process_javascript
    self.processed_javascript = input_javascript
  end

  def process_css
    scoped_scss = ".block-wrapper-#{id} { #{input_css}}"
    se = Sass::Engine.new(scoped_scss, syntax: :scss)
    self.processed_css = se.render
  end

  def permissions
    return if user&.has_role?(:super_admin)

    errors.add(:commentable_id, "is not valid.")
  end
end

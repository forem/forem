ActiveRecord::Base.connection.create_table :users, force: true do |t|
end

class User < ActiveRecord::Base
  has_many :posts
  has_many :drafts, -> { where draft: true  }, class_name: "Post"
end unless defined?(User)

ActiveRecord::Base.connection.create_table :posts, force: true do |t|
  t.integer   :user_id
  t.boolean   :draft
  t.timestamp :published_at
  t.timestamps null: false
end

class Post < ActiveRecord::Base
  belongs_to :user
end unless defined?(Post)

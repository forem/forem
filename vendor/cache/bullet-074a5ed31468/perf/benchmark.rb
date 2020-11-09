# frozen_string_literal: true

$LOAD_PATH << 'lib'
require 'benchmark'
require 'rails'
require 'active_record'
require 'activerecord-import'
require 'bullet'

begin
  require 'perftools'
rescue LoadError
  puts "Could not load perftools.rb, profiling won't be possible"
end

class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
end

class User < ActiveRecord::Base
  has_many :posts
  has_many :comments
end

# create database bullet_benchmark;
ActiveRecord::Base.establish_connection(
  adapter: 'mysql2', database: 'bullet_benchmark', server: '/tmp/mysql.socket', username: 'root'
)

ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }

ActiveRecord::Schema.define(version: 1) do
  create_table :posts do |t|
    t.column :title, :string
    t.column :body, :string
    t.column :user_id, :integer
  end

  create_table :comments do |t|
    t.column :body, :string
    t.column :post_id, :integer
    t.column :user_id, :integer
  end

  create_table :users do |t|
    t.column :name, :string
  end
end

users_size = 100
posts_size = 1_000
comments_size = 10_000
users = []
users_size.times { |i| users << User.new(name: "user#{i}") }
User.import users
users = User.all

posts = []
posts_size.times { |i| posts << Post.new(title: "Title #{i}", body: "Body #{i}", user: users[i % 100]) }
Post.import posts
posts = Post.all

comments = []
comments_size.times { |i| comments << Comment.new(body: "Comment #{i}", post: posts[i % 1_000], user: users[i % 100]) }
Comment.import comments

puts 'Start benchmarking...'

Bullet.enable = true

Benchmark.bm(70) do |bm|
  bm.report("Querying & Iterating #{posts_size} Posts with #{comments_size} Comments and #{users_size} Users") do
    10.times do
      Bullet.start_request
      Post.select('SQL_NO_CACHE *').includes(:user, comments: :user).each do |p|
        p.title
        p.user.name
        p.comments.each do |c|
          c.body
          c.user.name
        end
      end
      Bullet.end_request
    end
  end
end

puts 'End benchmarking...'

# Run benchmark with bundler
#
#     bundle exec ruby perf/benchmark.rb
#
# bullet 2.3.0 with rails 3.2.2
#                                                                              user     system      total        real
# Querying & Iterating 1000 Posts with 10000 Comments and 100 Users       16.460000   0.190000  16.650000 ( 16.968246)
#
# bullet 2.3.0 with rails 3.1.4
#                                                                              user     system      total        real
# Querying & Iterating 1000 Posts with 10000 Comments and 100 Users       14.600000   0.130000  14.730000 ( 14.937590)
#
# bullet 2.3.0 with rails 3.0.12
#                                                                              user     system      total        real
# Querying & Iterating 1000 Posts with 10000 Comments and 100 Users       26.120000   0.430000  26.550000 ( 27.179304)
#
#
# bullet 2.2.1 with rails 3.0.12
#                                                                              user     system      total        real
# Querying & Iterating 1000 Posts with 10000 Comments and 100 Users       29.970000   0.270000  30.240000 ( 30.452083)

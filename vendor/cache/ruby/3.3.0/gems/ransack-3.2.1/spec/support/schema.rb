require 'active_record'

case ENV['DB'].try(:downcase)
when 'mysql', 'mysql2'
  # To test with MySQL: `DB=mysql bundle exec rake spec`
  ActiveRecord::Base.establish_connection(
    adapter:  'mysql2',
    database: 'ransack',
    username: ENV.fetch("MYSQL_USERNAME") { "root" },
    password: ENV.fetch("MYSQL_PASSWORD") { "" },
    encoding: 'utf8'
  )
when 'pg', 'postgres', 'postgresql'
  # To test with PostgreSQL: `DB=postgresql bundle exec rake spec`
  ActiveRecord::Base.establish_connection(
    adapter: 'postgresql',
    database: 'ransack',
    username: ENV.fetch("DATABASE_USERNAME") { "postgres" },
    password: ENV.fetch("DATABASE_PASSWORD") { "" },
    host: ENV.fetch("DATABASE_HOST") { "localhost" },
    min_messages: 'warning'
  )
else
  # Otherwise, assume SQLite3: `bundle exec rake spec`
  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: ':memory:'
  )
end

class Person < ActiveRecord::Base
  default_scope { order(id: :desc) }
  belongs_to :parent, class_name: 'Person', foreign_key: :parent_id
  has_many   :children, class_name: 'Person', foreign_key: :parent_id
  has_many   :articles
  has_many   :story_articles

  has_many :published_articles, ->{ where(published: true) },
      class_name: "Article"
  has_many   :comments
  has_many   :authored_article_comments, through: :articles,
             source: :comments, foreign_key: :person_id
  has_many   :notes, as: :notable

  scope :restricted,  lambda { where("restricted = 1") }
  scope :active,      lambda { where("active = 1") }
  scope :over_age,    lambda { |y| where(["age > ?", y]) }
  scope :of_age,      lambda { |of_age|
    of_age ? where("age >= ?", 18) : where("age < ?", 18)
  }

  scope :sort_by_reverse_name_asc, lambda { order(Arel.sql("REVERSE(name) ASC")) }
  scope :sort_by_reverse_name_desc, lambda { order("REVERSE(name) DESC") }

  alias_attribute :full_name, :name

  ransack_alias :term, :name_or_email
  ransack_alias :daddy, :parent_name

  ransacker :reversed_name, formatter: proc { |v| v.reverse } do |parent|
    parent.table[:name]
  end

  ransacker :array_people_ids,
    formatter: proc { |v| Person.first(2).map(&:id) } do |parent|
    parent.table[:id]
  end

  ransacker :array_where_people_ids,
    formatter: proc { |v| Person.where(id: v).map(&:id) } do |parent|
    parent.table[:id]
  end

  ransacker :array_people_names,
    formatter: proc { |v| Person.first(2).map { |p| p.id.to_s } } do |parent|
    parent.table[:name]
  end

  ransacker :array_where_people_names,
    formatter: proc { |v| Person.where(id: v).map { |p| p.id.to_s } } do |parent|
    parent.table[:name]
  end

  ransacker :doubled_name do |parent|
    Arel::Nodes::InfixOperation.new(
      '||', parent.table[:name], parent.table[:name]
      )
  end

  ransacker :sql_literal_id do
    Arel.sql('people.id')
  end

  ransacker :name_case_insensitive, type: :string do
    arel_table[:name].lower
  end

  ransacker :with_arguments, args: [:parent, :ransacker_args] do |parent, args|
    min, max = args
    query = <<-SQL
      (SELECT MAX(articles.title)
         FROM articles
        WHERE articles.person_id = people.id
          AND LENGTH(articles.body) BETWEEN #{min} AND #{max}
        GROUP BY articles.person_id
      )
    SQL
    .squish
    Arel.sql(query)
  end

  def self.ransackable_attributes(auth_object = nil)
    if auth_object == :admin
      super - ['only_sort']
    else
      super - ['only_sort', 'only_admin']
    end
  end

  def self.ransortable_attributes(auth_object = nil)
    if auth_object == :admin
      column_names + _ransackers.keys - ['only_search']
    else
      column_names + _ransackers.keys - ['only_search', 'only_admin']
    end
  end
end

class Musician < Person
end

class Article < ActiveRecord::Base
  belongs_to :person
  has_many :comments
  has_and_belongs_to_many :tags
  has_many :notes, as: :notable

  alias_attribute :content, :body

  default_scope { where("'default_scope' = 'default_scope'") }
  scope :latest_comment_cont, lambda { |msg|
    join = <<-SQL
      (LEFT OUTER JOIN (
          SELECT
            comments.*,
            row_number() OVER (PARTITION BY comments.article_id ORDER BY comments.id DESC) AS rownum
          FROM comments
        ) AS latest_comment
        ON latest_comment.article_id = article.id
        AND latest_comment.rownum = 1
      )
    SQL
    .squish

    joins(join).where("latest_comment.body ILIKE ?", "%#{msg}%")
  }

  ransacker :title_type, formatter: lambda { |tuples|
    title, type = JSON.parse(tuples)
    Arel::Nodes::Grouping.new(
      [
        Arel::Nodes.build_quoted(title),
        Arel::Nodes.build_quoted(type)
      ]
    )
  } do |_parent|
    articles = Article.arel_table
    Arel::Nodes::Grouping.new(
      %i[title type].map do |field|
        Arel::Nodes::NamedFunction.new(
          'COALESCE',
          [
            Arel::Nodes::NamedFunction.new('TRIM', [articles[field]]),
            Arel::Nodes.build_quoted('')
          ]
        )
      end
    )
  end
end

class StoryArticle < Article
end

class Recommendation < ActiveRecord::Base
  belongs_to :person
  belongs_to :target_person, class_name: 'Person'
  belongs_to :article
end

module Namespace
  class Article < ::Article

  end
end

module Namespace
  class Article < ::Article

  end
end

class Comment < ActiveRecord::Base
  belongs_to :article
  belongs_to :person

  default_scope { where(disabled: false) }
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :articles
end

class Note < ActiveRecord::Base
  belongs_to :notable, polymorphic: true
end

class Account < ActiveRecord::Base
  belongs_to :agent_account, class_name: "Account"
  belongs_to :trade_account, class_name: "Account"
end

module Schema
  def self.create
    ActiveRecord::Migration.verbose = false

    ActiveRecord::Schema.define do
      create_table :people, force: true do |t|
        t.integer  :parent_id
        t.string   :name
        t.string   :email
        t.string   :only_search
        t.string   :only_sort
        t.string   :only_admin
        t.string   :new_start
        t.string   :stop_end
        t.integer  :salary
        t.date     :life_start
        t.boolean  :awesome, default: false
        t.boolean  :terms_and_conditions, default: false
        t.boolean  :true_or_false, default: true
        t.timestamps null: false
      end

      create_table :articles, force: true do |t|
        t.integer  :person_id
        t.string   :title
        t.text     :subject_header
        t.text     :body
        t.string   :type
        t.boolean  :published, default: true
      end

      create_table :comments, force: true do |t|
        t.integer  :article_id
        t.integer  :person_id
        t.text     :body
        t.boolean  :disabled, default: false
      end

      create_table :tags, force: true do |t|
        t.string   :name
      end

      create_table :articles_tags, force: true, id: false do |t|
        t.integer  :article_id
        t.integer  :tag_id
      end

      create_table :notes, force: true do |t|
        t.integer  :notable_id
        t.string   :notable_type
        t.string   :note
      end

      create_table :recommendations, force: true do |t|
        t.integer  :person_id
        t.integer  :target_person_id
        t.integer  :article_id
      end

      create_table :accounts, force: true do |t|
        t.belongs_to :agent_account
        t.belongs_to :trade_account
      end
    end

    10.times do
      person = Person.make
      Note.make(notable: person)
      3.times do
        article = Article.make(person: person)
        3.times do
          article.tags = [Tag.make, Tag.make, Tag.make]
        end
        Note.make(notable: article)
        10.times do
          Comment.make(article: article, person: person)
        end
      end
    end

    Comment.make(
      body: 'First post!',
      article: Article.make(title: 'Hello, world!')
    )
  end
end

module SubDB
  class Base < ActiveRecord::Base
    self.abstract_class = true
    establish_connection(
      adapter: 'sqlite3',
      database: ':memory:'
    )
  end

  class OperationHistory < Base
  end

  module Schema
    def self.create
      s = ::ActiveRecord::Schema.new
      s.instance_variable_set(:@connection, SubDB::Base.connection)
      s.verbose = false
      s.define({}) do
        create_table :operation_histories, force: true do |t|
          t.string  :operation_type
          t.integer :people_id
        end
      end
    end
  end
end

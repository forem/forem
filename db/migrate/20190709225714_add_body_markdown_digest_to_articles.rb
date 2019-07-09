class AddBodyMarkdownDigestToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :body_markdown_digest, :string, limit: 40, null: false

    Article.find_each(:batch_size => 1000) do |article|
      article.save!
    end
  end
end

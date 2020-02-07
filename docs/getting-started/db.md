---
title: Preparing the Database
---

# Preparing the database

The next step is to create and prepare the database. Because DEV is a Rails
application, we have built-in tools to help us.

We can use Rails to create our database, load the schema, and add some seed
data:

```shell
rails db:setup
```

Note: If you've already run `bin/setup`, this will have already been done for
you.

`db:setup` actually runs the following rake commands in order so alternatively,
you could run each of these to produce the same result:

```shell
rails db:create
rails db:schema:load
rails db:seed
```

## Seed Data

By default, the amount of articles and users generated is quite tiny so that
contributors experience a quick installation. If you require more data for your
local installation, you can modify the `/db/seeds.rb` to tailor the amount of
data generated. Make these modifications to the seeds file before running
`bin/setup` or `rails db:setup`.

In the code snippet below, you'll see the line `25.times do |i|` which means it
will loop 25 times creating 25 random articles. So if you wanted to generate 100
random articles, simply change that line to `100.times do |i|`

```ruby
Rails.logger.info "4. Creating Articles"

Article.clear_index!
25.times do |i|
  tags = []
  tags << "discuss" if (i % 3).zero?
  tags.concat Tag.order(Arel.sql("RANDOM()")).select("name").first(3).map(&:name)

  markdown = <<~MARKDOWN
    ---
    title:  #{Faker::Book.unique.title}
    published: true
    cover_image: #{Faker::Company.logo}
    tags: #{tags.join(', ')}
    ---

    #{Faker::Hipster.paragraph(sentence_count: 2)}
    #{Faker::Markdown.random}
    #{Faker::Hipster.paragraph(sentence_count: 2)}
  MARKDOWN

  Article.create!(
    body_markdown: markdown,
    featured: true,
    show_comments: true,
    user_id: User.order(Arel.sql("RANDOM()")).first.id,
  )
end
```

The same can be done for generating more users and other entitities. There are
plans to improve on this so that a developer need not modify the seeds file, but
nothing concrete has been decided yet.

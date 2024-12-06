<p align="center">
  <a href="https://www.algolia.com">
    <img alt="Algolia for Rails" src="https://raw.githubusercontent.com/algolia/algoliasearch-client-common/master/banners/rails.png"/>
  </a>
</p>

<h4 align="center">The perfect starting point to integrate <a href="https://algolia.com" target="_blank">Algolia</a> within your Rails project</h4>

<p align="center">
  <a href="https://circleci.com/gh/algolia/algoliasearch-rails"><img src="https://circleci.com/gh/algolia/algoliasearch-rails.svg?style=shield" alt="CircleCI" /></a>
  <a href="http://badge.fury.io/rb/algoliasearch-rails"><img src="https://badge.fury.io/rb/algoliasearch-rails.svg" alt="Gem Version"/></a>
  <a href="https://codeclimate.com/github/algolia/algoliasearch-rails"><img src="https://codeclimate.com/github/algolia/algoliasearch-rails.svg" alt="Code Climate"/></a>
  <img src="https://img.shields.io/badge/ActiveRecord-yes-blue.svg?style=flat-square" alt="ActiveRecord"/>
  <img src="https://img.shields.io/badge/Mongoid-yes-blue.svg?style=flat-square" alt="Mongoid"/>
  <img src="https://img.shields.io/badge/Sequel-yes-blue.svg?style=flat-square" alt="Sequel"/>
</p>

<p align="center">
  <a href="https://www.algolia.com/doc/framework-integration/rails/getting-started/setup/?language=ruby" target="_blank">Documentation</a>  •
  <a href="https://discourse.algolia.com" target="_blank">Community Forum</a>  •
  <a href="http://stackoverflow.com/questions/tagged/algolia" target="_blank">Stack Overflow</a>  •
  <a href="https://github.com/algolia/algoliasearch-rails/issues" target="_blank">Report a bug</a>  •
  <a href="https://www.algolia.com/doc/framework-integration/rails/troubleshooting/faq/" target="_blank">FAQ</a>  •
  <a href="https://www.algolia.com/support" target="_blank">Support</a>
</p>


This gem let you easily integrate the Algolia Search API to your favorite ORM. It's based on the [algoliasearch-client-ruby](https://github.com/algolia/algoliasearch-client-ruby) gem.
Rails 5.x and 6.x are supported.

You might be interested in the sample Ruby on Rails application providing a `autocomplete.js`-based auto-completion and `InstantSearch.js`-based instant search results page: [algoliasearch-rails-example](https://github.com/algolia/algoliasearch-rails-example/).



## API Documentation

You can find the full reference on [Algolia's website](https://www.algolia.com/doc/framework-integration/rails/).



1. **[Setup](#setup)**
    * [Install](#install)
    * [Configuration](#configuration)
    * [Timeouts](#timeouts)
    * [Notes](#notes)

1. **[Usage](#usage)**
    * [Index Schema](#index-schema)
    * [Relevancy](#relevancy)
    * [Indexing](#indexing)
    * [Frontend Search (realtime experience)](#frontend-search-realtime-experience)
    * [Backend Search](#backend-search)
    * [Backend Pagination](#backend-pagination)
    * [Tags](#tags)
    * [Faceting](#faceting)
    * [Faceted search](#faceted-search)
    * [Group by](#group-by)
    * [Geo-Search](#geo-search)

1. **[Options](#options)**
    * [Auto-indexing &amp; asynchronism](#auto-indexing--asynchronism)
    * [Custom index name](#custom-index-name)
    * [Per-environment indices](#per-environment-indices)
    * [Custom attribute definition](#custom-attribute-definition)
    * [Nested objects/relations](#nested-objectsrelations)
    * [Custom <code>objectID</code>](#custom-objectid)
    * [Restrict indexing to a subset of your data](#restrict-indexing-to-a-subset-of-your-data)
    * [Sanitizer](#sanitizer)
    * [UTF-8 Encoding](#utf-8-encoding)
    * [Exceptions](#exceptions)
    * [Configuration example](#configuration-example)

1. **[Indices](#indices)**
    * [Manual indexing](#manual-indexing)
    * [Manual removal](#manual-removal)
    * [Reindexing](#reindexing)
    * [Clearing an index](#clearing-an-index)
    * [Using the underlying index](#using-the-underlying-index)
    * [Primary/replica](#primaryreplica)
    * [Share a single index](#share-a-single-index)
    * [Target multiple indices](#target-multiple-indices)

1. **[Testing](#testing)**
    * [Notes](#notes)

1. **[Troubleshooting](#troubleshooting)**
    * [Frequently asked questions](#frequently-asked-questions)



# Setup



## Install

```sh
gem install algoliasearch-rails
```

Add the gem to your <code>Gemfile</code>:

```ruby
gem "algoliasearch-rails"
```

And run:

```sh
bundle install
```

## Configuration

Create a new file <code>config/initializers/algoliasearch.rb</code> to setup your <code>APPLICATION_ID</code> and <code>API_KEY</code>.

```ruby
AlgoliaSearch.configuration = { application_id: 'YourApplicationID', api_key: 'YourAPIKey' }
```

The gem is compatible with [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord), [Mongoid](https://github.com/mongoid/mongoid) and [Sequel](https://github.com/jeremyevans/sequel).

## Timeouts

You can configure a various timeout thresholds by setting the following options at initialization time:

```ruby
AlgoliaSearch.configuration = {
  application_id: 'YourApplicationID',
  api_key: 'YourAPIKey',
  connect_timeout: 2,
  receive_timeout: 30,
  send_timeout: 30,
  batch_timeout: 120,
  search_timeout: 5
}
```

## Notes

This gem makes extensive use of Rails' callbacks to trigger the indexing tasks. If you're using methods bypassing `after_validation`, `before_save` or `after_commit` callbacks, it will not index your changes. For example: `update_attribute` doesn't perform validations checks, to perform validations when updating use `update_attributes`.

All methods injected by the `AlgoliaSearch` module are prefixed by `algolia_` and aliased to the associated short names if they aren't already defined.

```ruby
Contact.algolia_reindex! # <=> Contact.reindex!

Contact.algolia_search("jon doe") # <=> Contact.search("jon doe")
```



# Usage



## Index Schema

The following code will create a <code>Contact</code> index and add search capabilities to your <code>Contact</code> model:

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch do
    attributes :first_name, :last_name, :email
  end
end
```

You can either specify the attributes to send (here we restricted to <code>:first_name, :last_name, :email</code>) or not (in that case, all attributes are sent).

```ruby
class Product < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch do
    # all attributes will be sent
  end
end
```

You can also use the <code>add_attribute</code> method, to send all model attributes + extra ones:

```ruby
class Product < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch do
    # all attributes + extra_attr will be sent
    add_attribute :extra_attr
  end

  def extra_attr
    "extra_val"
  end
end
```

## Relevancy

We provide many ways to configure your index allowing you to tune your overall index relevancy. The most important ones are the **searchable attributes** and the attributes reflecting **record popularity**.

```ruby
class Product < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch do
    # list of attribute used to build an Algolia record
    attributes :title, :subtitle, :description, :likes_count, :seller_name

    # the `searchableAttributes` (formerly known as attributesToIndex) setting defines the attributes
    # you want to search in: here `title`, `subtitle` & `description`.
    # You need to list them by order of importance. `description` is tagged as
    # `unordered` to avoid taking the position of a match into account in that attribute.
    searchableAttributes ['title', 'subtitle', 'unordered(description)']

    # the `customRanking` setting defines the ranking criteria use to compare two matching
    # records in case their text-relevance is equal. It should reflect your record popularity.
    customRanking ['desc(likes_count)']
  end

end
```

## Indexing

To index a model, simple call `reindex` on the class:

```ruby
Product.reindex
```

To index all of your models, you can do something like this:

```ruby
Rails.application.eager_load! # Ensure all models are loaded (required in development).

algolia_models = ActiveRecord::Base.descendants.select{ |model| model.respond_to?(:reindex) }

algolia_models.each(&:reindex)
```

## Frontend Search (realtime experience)

Traditional search implementations tend to have search logic and functionality on the backend. This made sense when the search experience consisted of a user entering a search query, executing that search, and then being redirected to a search result page.

Implementing search on the backend is no longer necessary. In fact, in most cases it is harmful to performance because of added network and processing latency. We highly recommend the usage of our [JavaScript API Client](https://github.com/algolia/algoliasearch-client-javascript) issuing all search requests directly from the end user's browser, mobile device, or client. It will reduce the overall search latency while offloading your servers at the same time.

The JS API client is part of the gem, just require `algolia/v3/algoliasearch.min` somewhere in your JavaScript manifest, for example in `application.js` if you are using Rails 3.1+:

```javascript
//= require algolia/v3/algoliasearch.min
```

Then in your JavaScript code you can do:

```js
var client = algoliasearch(ApplicationID, Search-Only-API-Key);
var index = client.initIndex('YourIndexName');
index.search('something', { hitsPerPage: 10, page: 0 })
  .then(function searchDone(content) {
    console.log(content)
  })
  .catch(function searchFailure(err) {
    console.error(err);
  });
```

**We recently (March 2015) released a new version (V3) of our JavaScript client, if you were using our previous version (V2), [read the migration guide](https://github.com/algolia/algoliasearch-client-javascript/wiki/Migration-guide-from-2.x.x-to-3.x.x)**

## Backend Search

***Notes:*** We recommend the usage of our [JavaScript API Client](https://github.com/algolia/algoliasearch-client-javascript) to perform queries directly from the end-user browser without going through your server.

A search returns ORM-compliant objects reloading them from your database. We recommend the usage of our [JavaScript API Client](https://github.com/algolia/algoliasearch-client-javascript) to perform queries to decrease the overall latency and offload your servers.

```ruby
hits =  Contact.search("jon doe")
p hits
p hits.raw_answer # to get the original JSON raw answer
```

A `highlight_result` attribute is added to each ORM object:

```ruby
hits[0].highlight_result['first_name']['value']
```

If you want to retrieve the raw JSON answer from the API, without re-loading the objects from the database, you can use:

```ruby
json_answer = Contact.raw_search("jon doe")
p json_answer
p json_answer['hits']
p json_answer['facets']
```

Search parameters can be specified either through the index's [settings](https://github.com/algolia/algoliasearch-client-ruby#index-settings-parameters) statically in your model or dynamically at search time specifying [search parameters](https://github.com/algolia/algoliasearch-client-ruby#search) as second argument of the `search` method:

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch do
    attribute :first_name, :last_name, :email

    # default search parameters stored in the index settings
    minWordSizefor1Typo 4
    minWordSizefor2Typos 8
    hitsPerPage 42
  end
end
```

```ruby
# dynamical search parameters
p Contact.raw_search('jon doe', { hitsPerPage: 5, page: 2 })
```

## Backend Pagination

Even if we **highly recommend to perform all search (and therefore pagination) operations from your frontend using JavaScript**, we support both [will_paginate](https://github.com/mislav/will_paginate) and [kaminari](https://github.com/amatsuda/kaminari) as pagination backend.

To use <code>:will_paginate</code>, specify the <code>:pagination_backend</code> as follow:

```ruby
AlgoliaSearch.configuration = { application_id: 'YourApplicationID', api_key: 'YourAPIKey', pagination_backend: :will_paginate }
```

Then, as soon as you use the `search` method, the returning results will be a paginated set:

```ruby
# in your controller
@results = MyModel.search('foo', hitsPerPage: 10)

# in your views
# if using will_paginate
<%= will_paginate @results %>

# if using kaminari
<%= paginate @results %>
```

## Tags

Use the <code>tags</code> method to add tags to your record:

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch do
    tags ['trusted']
  end
end
```

or using dynamical values:

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch do
    tags do
      [first_name.blank? || last_name.blank? ? 'partial' : 'full', has_valid_email? ? 'valid_email' : 'invalid_email']
    end
  end
end
```

At query time, specify <code>{ tagFilters: 'tagvalue' }</code> or <code>{ tagFilters: ['tagvalue1', 'tagvalue2'] }</code> as search parameters to restrict the result set to specific tags.

## Faceting

Facets can be retrieved calling the extra `facets` method of the search answer.

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch do
    # [...]

    # specify the list of attributes available for faceting
    attributesForFaceting [:company, :zip_code]
  end
end
```

```ruby
hits = Contact.search('jon doe', { facets: '*' })
p hits                    # ORM-compliant array of objects
p hits.facets             # extra method added to retrieve facets
p hits.facets['company']  # facet values+count of facet 'company'
p hits.facets['zip_code'] # facet values+count of facet 'zip_code'
```

```ruby
raw_json = Contact.raw_search('jon doe', { facets: '*' })
p raw_json['facets']
```

## Faceted search

You can also search for facet values.

```ruby
Product.search_for_facet_values('category', 'Headphones') # Array of {value, highlighted, count}
```

This method can also take any parameter a query can take.
This will adjust the search to only hits which would have matched the query.

```ruby
# Only sends back the categories containing red Apple products (and only counts those)
Product.search_for_facet_values('category', 'phone', {
  query: 'red',
  filters: 'brand:Apple'
}) # Array of phone categories linked to red Apple products
```

## Group by

More info on distinct for grouping can be found
[here](https://www.algolia.com/doc/guides/managing-results/refine-results/grouping/).

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch do
    # [...]

    # specify the attribute to be used for distinguishing the records
    # in this case the records will be grouped by company
    attributeForDistinct "company"
  end
end
```

## Geo-Search

Use the <code>geoloc</code> method to localize your record:

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch do
    geoloc :lat_attr, :lng_attr
  end
end
```

At query time, specify <code>{ aroundLatLng: "37.33, -121.89", aroundRadius: 50000 }</code> as search parameters to restrict the result set to 50KM around San Jose.



# Options



## Auto-indexing & asynchronism

Each time a record is saved, it will be *asynchronously* indexed. On the other hand, each time a record is destroyed, it will be - asynchronously - removed from the index. That means that a network call with the ADD/DELETE operation is sent **synchronously** to the Algolia API but then the engine will **asynchronously** process the operation (so if you do a search just after, the results may not reflect it yet).

You can disable auto-indexing and auto-removing setting the following options:

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch auto_index: false, auto_remove: false do
    attribute :first_name, :last_name, :email
  end
end
```

### Temporary disable auto-indexing

You can temporary disable auto-indexing using the <code>without_auto_index</code> scope. This is often used for performance reason.

```ruby
Contact.delete_all
Contact.without_auto_index do
  1.upto(10000) { Contact.create! attributes } # inside this block, auto indexing task will not run.
end
Contact.reindex! # will use batch operations
```

### Queues & background jobs

You can configure the auto-indexing & auto-removal process to use a queue to perform those operations in background. ActiveJob (Rails >=4.2) queues are used by default but you can define your own queuing mechanism:

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch enqueue: true do # ActiveJob will be triggered using a `algoliasearch` queue
    attribute :first_name, :last_name, :email
  end
end
```

### Things to Consider

If you are performing updates & deletions in the background then a record deletion can be committed to your database prior
to the job actually executing. Thus if you were to load the record to remove it from the database than your ActiveRecord#find will fail with a RecordNotFound.

In this case you can bypass loading the record from ActiveRecord and just communicate with the index directly:

```ruby
class MySidekiqWorker
  def perform(id, remove)
    if remove
      # the record has likely already been removed from your database so we cannot
      # use ActiveRecord#find to load it
      index = AlgoliaSearch.client.init_index("index_name")
      index.delete_object(id)
    else
      # the record should be present
      c = Contact.find(id)
      c.index!
    end
  end
end
```

### With Sidekiq

If you're using [Sidekiq](https://github.com/mperham/sidekiq):

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch enqueue: :trigger_sidekiq_worker do
    attribute :first_name, :last_name, :email
  end

  def self.trigger_sidekiq_worker(record, remove)
    MySidekiqWorker.perform_async(record.id, remove)
  end
end

class MySidekiqWorker
  def perform(id, remove)
    if remove
      # the record has likely already been removed from your database so we cannot
      # use ActiveRecord#find to load it
      index = AlgoliaSearch.client.init_index("index_name")
      index.delete_object(id)
    else
      # the record should be present
      c = Contact.find(id)
      c.index!
    end
  end
end
```

### With DelayedJob

If you're using [delayed_job](https://github.com/collectiveidea/delayed_job):

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch enqueue: :trigger_delayed_job do
    attribute :first_name, :last_name, :email
  end

  def self.trigger_delayed_job(record, remove)
    if remove
      record.delay.remove_from_index!
    else
      record.delay.index!
    end
  end
end

```

### Synchronism & testing

You can force indexing and removing to be synchronous (in that case the gem will call the `wait_task` method to ensure the operation has been taken into account once the method returns) by setting the following option: (this is **NOT** recommended, except for testing purpose)

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch synchronous: true do
    attribute :first_name, :last_name, :email
  end
end
```

## Custom index name

By default, the index name will be the class name, e.g. "Contact". You can customize the index name by using the `index_name` option:

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch index_name: "MyCustomName" do
    attribute :first_name, :last_name, :email
  end
end
```

## Per-environment indices

You can suffix the index name with the current Rails environment using the following option:

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch per_environment: true do # index name will be "Contact_#{Rails.env}"
    attribute :first_name, :last_name, :email
  end
end
```

## Custom attribute definition

You can use a block to specify a complex attribute value

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch do
    attribute :email
    attribute :full_name do
      "#{first_name} #{last_name}"
    end
    add_attribute :full_name2
  end

  def full_name2
    "#{first_name} #{last_name}"
  end
end
```

***Notes:*** As soon as you use such code to define extra attributes, the gem is not anymore able to detect if the attribute has changed (the code uses Rails's `#{attribute}_changed?` method to detect that). As a consequence, your record will be pushed to the API even if its attributes didn't change. You can work-around this behavior creating a `_changed?` method:

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch do
    attribute :email
    attribute :full_name do
      "#{first_name} #{last_name}"
    end
  end

  def full_name_changed?
    first_name_changed? || last_name_changed?
  end
end
```

## Nested objects/relations

### Defining the relationship

You can easily embed nested objects defining an extra attribute returning any JSON-compliant object (an array or a hash or a combination of both).

```ruby
class Profile < ActiveRecord::Base
  include AlgoliaSearch

  belongs_to :user
  has_many :specializations

  algoliasearch do
    attribute :user do
      # restrict the nested "user" object to its `name` + `email`
      { name: user.name, email: user.email }
    end
    attribute :public_specializations do
      # build an array of public specialization (include only `title` and `another_attr`)
      specializations.select { |s| s.public? }.map do |s|
        { title: s.title, another_attr: s.another_attr }
      end
    end
  end

end
```

### Propagating the change from a nested child

#### With ActiveRecord

With ActiveRecord, we'll be using `touch` and `after_touch` to achieve this.

```ruby
# app/models/app.rb
class App < ApplicationRecord
  include AlgoliaSearch

  belongs_to :author, class_name: :User
  after_touch :index!

  algoliasearch do
    attribute :title
    attribute :author do
      author.as_json
    end
  end
end

# app/models/user.rb
class User < ApplicationRecord
  # If your association uses belongs_to
  # - use `touch: true`
  # - do not define an `after_save` hook
  has_many :apps, foreign_key: :author_id

  after_save { apps.each(&:touch) }
end
```

#### With Sequel

With Sequel, you can use the `touch` plugin to propagate the changes:

```ruby
# app/models/app.rb
class App < Sequel::Model
  include AlgoliaSearch

  many_to_one :author, class: :User

  plugin :timestamps
  plugin :touch

  algoliasearch do
    attribute :title
    attribute :author do
      author.to_hash
    end
  end
end

# app/models/user.rb
class User < Sequel::Model
  one_to_many :apps, key: :author_id

  plugin :timestamps
  # Can't use the associations since it won't trigger the after_save
  plugin :touch

  # Define the associations that need to be touched here
  # Less performant, but allows for the after_save hook to trigger
  def touch_associations
    apps.map(&:touch)
  end

  def touch
    super
    touch_associations
  end
end
```

## Custom `objectID`

By default, the `objectID` is based on your record's `id`. You can change this behavior specifying the `:id` option (be sure to use a uniq field).

```ruby
class UniqUser < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch id: :uniq_name do
  end
end
```

## Restrict indexing to a subset of your data

You can add constraints controlling if a record must be indexed by using options the `:if` or `:unless` options.

It allows you to do conditional indexing on a per document basis.

```ruby
class Post < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch if: :published?, unless: :deleted? do
  end

  def published?
    # [...]
  end

  def deleted?
    # [...]
  end
end
```

**Notes:** As soon as you use those constraints, `addObjects` and `deleteObjects` calls will be performed in order to keep the index synced with the DB (The state-less gem doesn't know if the object don't match your constraints anymore or never matched, so we force ADD/DELETE operations to be sent). You can work-around this behavior creating a `_changed?` method:

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch if: :published do
  end

  def published
    # true or false
  end

  def published_changed?
    # return true only if you know that the 'published' state changed
  end
end
```

You can index a subset of your records using either:

```ruby
# will generate batch API calls (recommended)
MyModel.where('updated_at > ?', 10.minutes.ago).reindex!
```

or

```ruby
MyModel.index_objects MyModel.limit(5)
```

## Sanitizer

You can sanitize all your attributes using the `sanitize` option. It will strip all HTML tags from your attributes.

```ruby
class User < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch per_environment: true, sanitize: true do
    attributes :name, :email, :company
  end
end

```

If you're using Rails 4.2+, you also need to depend on `rails-html-sanitizer`:

```ruby
gem 'rails-html-sanitizer'
```

## UTF-8 Encoding

You can force the UTF-8 encoding of all your attributes using the `force_utf8_encoding` option:

```ruby
class User < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch force_utf8_encoding: true do
    attributes :name, :email, :company
  end
end

```

***Notes:*** This option is not compatible with Ruby 1.8

## Exceptions

You can disable exceptions that could be raised while trying to reach Algolia's API by using the `raise_on_failure` option:

```ruby
class Contact < ActiveRecord::Base
  include AlgoliaSearch

  # only raise exceptions in development env
  algoliasearch raise_on_failure: Rails.env.development? do
    attribute :first_name, :last_name, :email
  end
end
```

## Configuration example

Here is a real-word configuration example (from [HN Search](https://github.com/algolia/hn-search)):

```ruby
class Item < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch per_environment: true do
    # the list of attributes sent to Algolia's API
    attribute :created_at, :title, :url, :author, :points, :story_text, :comment_text, :author, :num_comments, :story_id, :story_title

    # integer version of the created_at datetime field, to use numerical filtering
    attribute :created_at_i do
      created_at.to_i
    end

    # `title` is more important than `{story,comment}_text`, `{story,comment}_text` more than `url`, `url` more than `author`
    # btw, do not take into account position in most fields to avoid first word match boost
    searchableAttributes ['unordered(title)', 'unordered(story_text)', 'unordered(comment_text)', 'unordered(url)', 'author']

    # tags used for filtering
    tags do
      [item_type, "author_#{author}", "story_#{story_id}"]
    end

    # use associated number of HN points to sort results (last sort criteria)
    customRanking ['desc(points)', 'desc(num_comments)']

    # google+, $1.5M raises, C#: we love you
    separatorsToIndex '+#$'
  end

  def story_text
    item_type_cd != Item.comment ? text : nil
  end

  def story_title
    comment? && story ? story.title : nil
  end

  def story_url
    comment? && story ? story.url : nil
  end

  def comment_text
    comment? ? text : nil
  end

  def comment?
    item_type_cd == Item.comment
  end

  # [...]
end
```



# Indices



## Manual indexing

You can trigger indexing using the <code>index!</code> instance method.

```ruby
c = Contact.create!(params[:contact])
c.index!
```

## Manual removal

And trigger index removing using the <code>remove_from_index!</code> instance method.

```ruby
c.remove_from_index!
c.destroy
```

## Reindexing

The gem provides 2 ways to reindex all your objects:

### Atomical reindexing

To reindex all your records (taking into account the deleted objects), the `reindex` class method indices all your objects to a temporary index called `<INDEX_NAME>.tmp` and moves the temporary index to the final one once everything is indexed (atomically). This is the safest way to reindex all your content.

```ruby
Contact.reindex
```

**Notes**: if you're using an index-specific API key, ensure you're allowing both `<INDEX_NAME>` and `<INDEX_NAME>.tmp`.

**Warning:** You should not use such an atomic reindexing operation while scoping/filtering the model because this operation **replaces the entire index**, keeping the filtered objects only. ie: Don't do `MyModel.where(...).reindex` but do `MyModel.where(...).reindex!` (with the trailing `!`)!!!

### Regular reindexing

To reindex all your objects in place (without temporary index and therefore without deleting removed objects), use the `reindex!` class method:

```ruby
Contact.reindex!
```

## Clearing an index

To clear an index, use the <code>clear_index!</code> class method:

```ruby
Contact.clear_index!
```

## Using the underlying index

You can access the underlying `index` object by calling the `index` class method:

```ruby
index = Contact.index
# index.get_settings, index.partial_update_object, ...
```

## Primary/replica

You can define replica indices using the <code>add_replica</code> method.
Use `inherit: true` on the replica block if you want it  to inherit from the primary settings.

```ruby
class Book < ActiveRecord::Base
  attr_protected

  include AlgoliaSearch

  algoliasearch per_environment: true do
    searchableAttributes [:name, :author, :editor]

    # define a replica index to search by `author` only
    add_replica 'Book_by_author', per_environment: true do
      searchableAttributes [:author]
    end

    # define a replica index with custom ordering but same settings than the main block
    add_replica 'Book_custom_order', inherit: true, per_environment: true do
      customRanking ['asc(rank)']
    end
  end

end
```

To search using a replica, use the following code:

```ruby
Book.raw_search 'foo bar', replica: 'Book_by_editor'
# or
Book.search 'foo bar', replica: 'Book_by_editor'
```

## Share a single index

It can make sense to share an index between several models. In order to implement that, you'll need to ensure you don't have any conflict with the `objectID` of the underlying models.

```ruby
class Student < ActiveRecord::Base
  attr_protected

  include AlgoliaSearch

  algoliasearch index_name: 'people', id: :algolia_id do
    # [...]
  end

  private
  def algolia_id
    "student_#{id}" # ensure the teacher & student IDs are not conflicting
  end
end

class Teacher < ActiveRecord::Base
  attr_protected

  include AlgoliaSearch

  algoliasearch index_name: 'people', id: :algolia_id do
    # [...]
  end

  private
  def algolia_id
    "teacher_#{id}" # ensure the teacher & student IDs are not conflicting
  end
end
```

***Notes:*** If you target a single index from several models, you must never use `MyModel.reindex` and only use `MyModel.reindex!`. The `reindex` method uses a temporary index to perform an atomic reindexing: if you use it, the resulting index will only contain records for the current model because it will not reindex the others.

## Target multiple indices

You can index a record in several indices using the <code>add_index</code> method:

```ruby
class Book < ActiveRecord::Base
  attr_protected

  include AlgoliaSearch

  PUBLIC_INDEX_NAME  = "Book_#{Rails.env}"
  SECURED_INDEX_NAME = "SecuredBook_#{Rails.env}"

  # store all books in index 'SECURED_INDEX_NAME'
  algoliasearch index_name: SECURED_INDEX_NAME do
    searchableAttributes [:name, :author]
    # convert security to tags
    tags do
      [released ? 'public' : 'private', premium ? 'premium' : 'standard']
    end

    # store all 'public' (released and not premium) books in index 'PUBLIC_INDEX_NAME'
    add_index PUBLIC_INDEX_NAME, if: :public? do
      searchableAttributes [:name, :author]
    end
  end

  private
  def public?
    released && !premium
  end

end
```

To search using an extra index, use the following code:

```ruby
Book.raw_search 'foo bar', index: 'Book_by_editor'
# or
Book.search 'foo bar', index: 'Book_by_editor'
```



# Testing



## Notes

To run the specs, please set the <code>ALGOLIA_APPLICATION_ID</code> and <code>ALGOLIA_API_KEY</code> environment variables. Since the tests are creating and removing indices, DO NOT use your production account.

You may want to disable all indexing (add, update & delete operations) API calls, you can set the `disable_indexing` option:

```ruby
class User < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch per_environment: true, disable_indexing: Rails.env.test? do
  end
end

class User < ActiveRecord::Base
  include AlgoliaSearch

  algoliasearch per_environment: true, disable_indexing: Proc.new { Rails.env.test? || more_complex_condition } do
  end
end
```


## ❓ Troubleshooting

Encountering an issue? Before reaching out to support, we recommend heading to our [FAQ](https://www.algolia.com/doc/api-client/troubleshooting/faq/ruby/) where you will find answers for the most common issues and gotchas with the client.

## Use the Dockerfile

If you want to contribute to this project without installing all its dependencies, you can use our Docker image. Please check our [dedicated guide](DOCKER_README.MD) to learn more.


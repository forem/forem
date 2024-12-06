# Upgrading to v2 of the Ruby API client

## Gem
First, you'll have to include the new version in your Gemfile. To do so, change the following:

```diff
- gem 'algoliasearch'
+ gem 'algolia', git: 'https://github.com/algolia/algoliasearch-client-ruby.git', tag: 'v2.0.0-beta.1'
```

Then, you'll need to change your current `require` statements:

```diff
- require 'algoliasearch'
+ require 'algolia'
```

## Class names
All classes have been namespaced. The mostly used classes are now as follows:
 
- `Algolia::Client` -> `Algolia::Search::Client`
- `Algolia::Index` -> `Algolia::Search::Index`
- `Algolia::AccountClient` -> `Algolia::Account::Client`
- `Algolia::Analytics` -> `Algolia::Analytics::Client`
- `Algolia::Insights` -> `Algolia::Insights::Client`

## Initialize the client and index
There's a slight change in how you initialize the client. The index initialization didn't change.
```ruby
# Before
client = Algolia::Client.new(
   application_id: 'APP_ID',
   api_key: 'API_KEY'
)
index = client.init_index('index_name')

# After
client = Algolia::Search::Client.create('APP_ID', 'API_KEY')
index = client.init_index('index_name')
# or
search_config = Algolia::Search::Config.new(application_id: app_id, api_key: api_key)
client = Algolia::Search::Client.create_with_config(search_config)
index = client.init_index('index_name')
```

By default the keys of the response hashes are symbols. If you wish to change that for strings, use the following configuration
```ruby
search_config = Algolia::Search::Config.new(application_id: app_id, api_key: api_key, symbolize_keys: false)
client = Algolia::Search::Client.create_with_config(search_config)
```

## Search parameters and request options
The search parameters and request options are still optional, but they are combined into a single hash instead of two. 
For example:
```ruby
# Before
request_opts = { 'X-Algolia-UserToken': 'user123' }
search_params = { hitsPerPage: 50 }

index.search('query', search_params, request_opts)

# After
opts = {
  headers: { 'X-Algolia-UserToken': 'user123' },
  hitsPerPage: 50
}
index.search('query', opts)
```

## Methods

### `Client`

#### `set_extra_header`
The `set_extra_header` method has been moved from the Client to the `Algolia::BaseConfig` class. You have to define your extra headers on Client instantiation.
```ruby
# Before
client.set_extra_header('admin', 'admin-key')

# After
# `Algolia::Search::Config` inherits from `Algolia::BaseConfig` 
config = Algolia::Search::Config.new(app_id: 'APP_ID', api_key: 'API_KEY')
config.set_extra_header('admin', 'admin-key')

client = Algolia::Search::Client.create_with_config(config)
```

#### `multiple_queries`
The `strategy` parameter is no longer a string, but a key in the `requestOptions`.
```ruby
queries = [
  { indexName: 'index_name1', params: { query: 'query', hitsPerPage: 2 } },
  { indexName: 'index_name2', params: { query: 'another_query', hitsPerPage: 5 } }
]

# Before
client.multiple_queries(queries, 'stopIfEnoughMatches')

# After
client.multiple_queries(queries, { strategy: 'stopIfEnoughMatches' })
```

#### `copy_settings`
No change.

#### `list_indexes`
No change.

#### `copy_index`
No change.

#### `move_index`
No change.

#### `generate_secured_api_key`
This method is moved to the `Algolia::Search::Client` class.
```ruby
# Before
secured_api_key = Algolia.generate_secured_api_key('api_key', {
  validUntil: now - (10 * 60)
})

# After
secured_api_key = Algolia::Search::Client.generate_secured_api_key('api_key', {
  validUntil: now - (10 * 60)
})
```

#### `add_api_key`
`acl` is still the first parameter. The other parameters have been moved to the `requestOptions`.

```ruby
# Before
client.add_api_key({ acl: ['search'], description: 'A description', indexes: ['index']})

# After
client.add_api_key(['search'], {
  description: 'A description',
  indexes: ['index']
})
```

#### `update_api_key`
This method is moved to the `Algolia::Search::Client` class.
```ruby
# Before
Algolia.update_api_key('api_key', { maxHitsPerQuery: 42 })

# After
client.update_api_key('api_key', { maxHitsPerQuery: 42 })
```

#### `delete_api_key`
No change.

#### `restore_api_key`
No change.

#### `get_api_key`
No change.

#### `list_api_keys`
No change.

#### `get_secured_api_key_remaining_validity`
This method is moved to the `Algolia::Search::Client` class.
```ruby
# Before
Algolia.get_secured_api_key_remaining_validity('api_key')

# After
Algolia::Search::Client.get_secured_api_key_remaining_validity('api_key')
```

#### `copy_synonyms`
No change.

#### `assign_user_id`
No change.

#### `assign_user_ids`
Newly added method to add multiple userIDs to a cluster.
```ruby
user_ids = ['1','2','3']

# Before
user_ids.each { |id| client.assign_user_id(id, 'my-cluster')}

# After
client.assign_user_ids(user_ids, 'my-cluster')
```

#### `get_top_user_id`
No change.

#### `get_user_id`
No change.

#### `list_clusters`
No change.

#### `list_user_ids`
The `page` and `hitsPerPage` parameters are now part of the `requestOptions`.
```ruby
# Before
page = 0
hits_per_page = 20
client.list_user_ids(page, hits_per_page)

# After
client.list_user_ids({ hitPerPage: 20, page: 0 })
```

#### `remove_user_id`
No change.

#### `search_user_ids`
The `clusterName`, `page` and `hitsPerPage` parameters are now part of the `requestOptions`.
```ruby
# Before
page = 0
hits_per_page = 12
client.search_user_ids('query', 'my-cluster', page, hits_per_page)

# After
client.search_user_ids('query', {clusterName: 'my-cluster', hitPerPage: 12, page: 0 })
```

#### `pending_mappings`
New method to check the status of your clusters' migration or user creation.
```ruby
client.pending_mappings?({ retrieveMappings: true })
``` 

#### `get_logs`
The `offset`, `length`, and `type` parameters are now part of the `requestOptions`.
```ruby
# Before
offset = 5
length = 100
puts client.get_logs(offset, length, 'all')

# After
client.get_logs({ offset: 5, length: 10, type: 'all' })
```

#### `copy_rules`
No change.

### `Index`
#### `search` 
`searchParameters` and `requestOptions` are a single parameter now. 

```ruby
# Before
request_opts = { 'X-Algolia-UserToken': 'user123' }
search_params = { hitsPerPage: 50 }

index.search('query', search_params, request_opts)

# After
opts = {
  headers: { 'X-Algolia-UserToken': 'user123' },
  hitsPerPage: 50
}
index.search('query', opts)
```

#### `search_for_facet_values`
`searchParameters` and `requestOptions` are a single parameter now.
```ruby
# Before
request_opts = { 'X-Algolia-UserToken': 'user123' }
search_params = { hitsPerPage: 50 }

index.search_for_facet_values('category', 'phone', search_params, request_opts)

# After
opts = {
  headers: { 'X-Algolia-UserToken': 'user123' },
  hitsPerPage: 50
}
index.search_for_facet_values('category', 'phone', opts)
```

#### `find_object`
The method takes a lambda, proc or block as the first argument (anything that responds to `call`), and the `requestOptions` as the second
```ruby
# Before
index.find_object({query: 'query', paginate: true}) { |hit| hit[:title].include?('algolia') }

# After
index.find_object(-> (hit) { hit[:title].include?('algolia') }, { query: 'query', paginate: true })
```

#### `get_object_position`
The classname has changed, not the method itself.
```ruby
# Before
position = Algolia::Index.get_object_position(results, 'object')

# After
position = Algolia::Search::Index.get_object_position(results, 'object')
```

#### `add_object` and `add_objects`
These methods have been removed in favor of `save_object` and `save_objects`.

#### `save_object` and `save_objects`
No change.

#### `partial_update_object`
The `objectID` parameter is removed. `create_if_not_exists` is now part of the `requestOptions` parameter.

```ruby
obj = { objectID: '1234', prop: 'value' }

# Before
create_if_not_exists = true
index.partial_update_object(obj, obj[:objectID], create_if_not_exists)

# After
index.partial_update_object(obj, { createIfNotExists: true })
```

#### `partial_update_objects`
The `create_if_not_exists` parameter is now part of the `requestOptions` parameter.

```ruby
# Before
create_if_not_exists = true
index.partial_update_objects(objects, create_if_not_exists)

# After
index.partial_update_objects(objects, { createIfNotExists: true })
```

#### `delete_object` and `delete_objects`
No change.

#### `replace_all_objects`
No change.

#### `delete_by`
No change.

#### `clear_index`
Renamed to `clear_objects`.
```ruby
# Before
index.clear_index

# After
index.clear_objects
```

#### `get_object` and `get_objects`
The `attributesToRetrieve` parameter is now part of the `requestOptions`.
```ruby
# Before
index.get_object('1234', ['title'])
index.get_objects([1,2,3], ['title'])

# After 
index.get_object('1234', { attributesToRetrieve: ['title'] })
index.get_objects([1,2,3], { attributesToRetrieve: ['title'] })
```

#### `multiple_get_objects`
No change.

#### `batch`
No change.

#### `get_settings`
No change.

#### `set_settings`
No change.

#### `delete_index`
Instead of calling the `delete_index` method on the client, you should call the `delete` method directly on the index object.

```ruby
# Before
client.delete_index('foo')

# After
index.delete
```

#### `browse`
Renamed to `browse_objects`.
```ruby
# Before
request_opts = { 'X-Algolia-UserToken': 'user123' }
index.browse({ query: 'query'}, nil, request_opts) do |hit|
  puts hit
end

# After
opts = {
  query: 'query',
  headers: { 'X-Algolia-UserToken': 'user123' }
}
index.browse_objects(opts) do |hit|
  puts hit
end
```

#### `index.exists?`
No change.

#### `save_synonym`
The `objectID` parameter has been removed, and should be part of the synonym hash.
```ruby
# Before
forward_to_replicas = true
index.save_synonym('one', { objectID: 'one', type: 'synonym', synonyms: %w(one two) }, forward_to_replicas)

# After
index.save_synonym({ objectID: 'one', type: 'synonym', synonyms: %w(one two) }, { forwardToReplicas: true})
```

#### `batch_synonyms`
Renamed to `save_synonyms`. `forwardToReplicas` and `replaceExistingSynonyms` parmameters are now part of `requestOptions`.
```ruby
# Before
forward_to_replicas = true
replace_existing_synonyms = true
index.batch_synonyms(synonyms, forward_to_replicas, replace_existing_synonyms)
# After
index.save_synonyms(synonyms, { forwardToReplicas: true, replaceExistingSynonyms: true })
```

#### `delete_synonym`
No change.

#### `clear_synonyms`
No change.

#### `get_synonym`
No change.

#### `search_synonyms`
No change.

#### `replace_all_synonyms`
No change.

#### `export_synonyms`
Renamed to `browse_synonyms`.
```ruby
# Before
synonyms = index.export_synonyms

# After
synonyms = index.browse_synonyms
```

#### `save_rule`
The `objectID` parameter has been removed, and should be part of the Rule object.
```ruby
# Before
index.save_rule('unique-id', {
  objectID: 'unique-id',
  condition: { anchoring: 'is', pattern: 'pattern' },
  consequence: {
   params: {
      query: {
        edits: [
          { type: 'remove', delete: 'pattern' }
        ]
      }
    }
  }
})

# After
index.save_rule({
  objectID: 'unique-id',
  condition: { anchoring: 'is', pattern: 'pattern' },
  consequence: {
   params: {
      query: {
        edits: [
          { type: 'remove', delete: 'pattern' }
        ]
      }
    }
  }
})
```

#### `batch_rules`
Renamed to `save_rules`. The `forwardToReplicas` and `clearExistingRules` parameters should now be part of the `requestOptions`.
```ruby
# Before
forward_to_replicas = true
clear_existing_rules = true
index.batch_rules(rules, forward_to_replicas, clear_existing_rules)

# After
index.save_rules(rules, { forwardToReplicas: true, clearExistingRules: true })
```

#### `get_rule`
No change.

#### `delete_rule`
The `forwardToReplicas` parameter is now part of the `requestOptions`.
```ruby
# Before
forward_to_replicas = true
index.delete_rule('rule-id', forward_to_replicas)

# After
index.delete_rule('rule-id', { forwardToReplicas: true })
```

#### `clear_rules`
The `forwardToReplicas` parameter is now part of the `requestOptions`.
```ruby
# Before
forward_to_replicas = true
index.clear_rules(forward_to_replicas)

# After
index.clear_rules({ forwardToReplicas: true })
```

#### `search_rules`
No change.

#### `replace_all_rules`
No change.

#### `export_rules`
Renamed to `browse_rules`.

### `AnalyticsClient`
#### `add_ab_test`
No change.

#### `get_ab_test`
No change.

#### `get_ab_tests`
No change.

#### `stop_ab_test`
No change.

#### `delete_ab_test`
No change.

### `InsightsClient`
#### `clicked_object_ids_after_search`
No change.

#### `clicked_object_ids`
No change.

#### `clicked_filters`
No change.

#### `converted_object_ids_after_search`
No change.

#### `converted_object_ids`
No change.

#### `converted_filters`
No change.

#### `viewed_object_ids`
No change.

#### `viewed_filters`
No change.

### `RecommendationClient`
#### `set_personalization_strategy`
This new method is available on the `Algolia::Recommendation::Client` class.

#### `set_personalization_strategy`
This new method is available on the `Algolia::Recommendation::Client` class.

## Configuring timeouts
You can configure timeouts by passing a custom `Algolia::Search::Config` object to the constructor of your client.
```ruby
# Before
client = Algolia::Client.new({
  application_id: 'app_id',
  api_key: 'api_key',
  connect_timeout: 2,
  receive_timeout: 10,
})

# After
search_config = Algolia::Search::Config.new(application_id: 'app_id', api_key: 'api_key', read_timeout: 10, connect_timeout: 2)
client = Algolia::Search::Client.create_with_config(search_config)
```

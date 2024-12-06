# gibbon

Gibbon is an API wrapper for MailChimp's [API](http://kb.mailchimp.com/api/).

[![Build Status](https://travis-ci.com/amro/gibbon.svg?branch=master)](https://app.travis-ci.com/github/amro/gibbon)

## Important Notes

Please read MailChimp's [Getting Started Guide](http://kb.mailchimp.com/api/article/api-3-overview).

Gibbon 3.0.0+ returns a `Gibbon::Response` instead of the response body directly. `Gibbon::Response` exposes the parsed response `body` and `headers`.

## Installation

    $ gem install gibbon

## Requirements

A MailChimp account and API key. You can see your API keys [here](http://admin.mailchimp.com/account/api).

## Usage

First, create a *one-time use instance* of `Gibbon::Request`:

```ruby
gibbon = Gibbon::Request.new(api_key: "your_api_key")
```

***Note*** Only reuse instances of Gibbon after terminating a call with a verb, which makes a request. Requests are light weight objects that update an internal path based on your call chain. When you terminate a call chain with a verb, a request instance makes a request and resets the path.

You can set an individual request's `timeout` and `open_timeout` like this:

```ruby
gibbon.timeout = 30
gibbon.open_timeout = 30
```

You can read about `timeout` and `open_timeout` in the [Net::HTTP](https://ruby-doc.org/stdlib-2.3.3/libdoc/net/http/rdoc/Net/HTTP.html) doc.

Now you can make requests using the resources defined in [MailChimp's docs](http://kb.mailchimp.com/api/resources). Resource IDs
are specified inline and a `CRUD` (`create`, `retrieve` (or `get`), `update`, `upsert`, or `delete`) verb initiates the request. `upsert` lets you update a record, if it exists, or insert it otherwise where supported by MailChimp's API.

***Note*** `upsert` requires Gibbon version 2.1.0 or newer!

You can specify `headers`, `params`, and `body` when calling a `CRUD` method. For example:

```ruby
gibbon.lists.retrieve(headers: {"SomeHeader": "SomeHeaderValue"}, params: {"query_param": "query_param_value"})
```

***Note*** `get` can be substituted for `retrieve` as of Gibbon version 3.4.1 or newer!

Of course, `body` is only supported on `create`, `update`, and `upsert` calls. Those map to HTTP `POST`, `PATCH`, and `PUT` verbs respectively.

You can set `api_key`, `timeout`, `open_timeout`, `faraday_adapter`, `proxy`, `symbolize_keys`, `logger`, and `debug` globally:

```ruby
Gibbon::Request.api_key = "your_api_key"
Gibbon::Request.timeout = 15
Gibbon::Request.open_timeout = 15
Gibbon::Request.symbolize_keys = true
Gibbon::Request.debug = false
```

For example, you could set the values above in an `initializer` file in your `Rails` app (e.g. your\_app/config/initializers/gibbon.rb).

Assuming you've set an `api_key` on Gibbon, you can conveniently make API calls on the class itself:

```ruby
Gibbon::Request.lists.retrieve
```

You can also set the environment variable `MAILCHIMP_API_KEY` and Gibbon will use it when you create an instance:

```ruby
gibbon = Gibbon::Request.new
```

***Note*** Substitute an underscore if a resource name contains a hyphen.

Pass `symbolize_keys: true` to use symbols (instead of strings) as hash keys in API responses.

```ruby
gibbon = Gibbon::Request.new(api_key: "your_api_key", symbolize_keys: true)
```

MailChimp's [resource documentation](http://kb.mailchimp.com/api/resources) is a list of available resources.

## Debug Logging

Pass `debug: true` to enable debug logging to STDOUT.

```ruby
gibbon = Gibbon::Request.new(api_key: "your_api_key", debug: true)
```

### Custom logger

Ruby `Logger.new` is used by default, but it can be overrided using:

```ruby
gibbon = Gibbon::Request.new(api_key: "your_api_key", debug: true, logger: MyLogger.new)
```

Logger can be also set by globally:

```ruby
Gibbon::Request.logger = MyLogger.new
```

## Examples

### Lists

Fetch first page of lists:

```ruby
gibbon.lists.retrieve
```

Retrieving a specific list looks like:

```ruby
gibbon.lists(list_id).retrieve
```

Retrieving a specific list's members looks like:

```ruby
gibbon.lists(list_id).members.retrieve
```

### Subscribers

Get first page of subscribers for a list:

```ruby
gibbon.lists(list_id).members.retrieve
```

By default the Mailchimp API returns 10 results. To set the count to 50:

```ruby
gibbon.lists(list_id).members.retrieve(params: {"count": "50"})
```

And to retrieve the next 50 members:

```ruby
gibbon.lists(list_id).members.retrieve(params: {"count": "50", "offset": "50"})
```

And to retrieve only subscribed members

```ruby
gibbon.lists(list_id).members.retrieve(params: {"count": "50", "offset": "50", "status": "subscribed"})
```

Subscribe a member to a list:

```ruby
gibbon.lists(list_id).members.create(body: {email_address: "foo@bar.com", status: "subscribed", merge_fields: {FNAME: "First Name", LNAME: "Last Name"}})
```

If you want to `upsert` instead, you would do the following:

```ruby
gibbon.lists(list_id).members(lower_case_md5_hashed_email_address).upsert(body: {email_address: "foo@bar.com", status: "subscribed", merge_fields: {FNAME: "First Name", LNAME: "Last Name"}})
```

You can also unsubscribe a member from a list:

```ruby
gibbon.lists(list_id).members(lower_case_md5_hashed_email_address).update(body: { status: "unsubscribed" })
```

Get a specific member's information (open/click rates etc.) from MailChimp:

```ruby
gibbon.lists(list_id).members(lower_case_md5_hashed_email_address).retrieve
```

Permanently delete a specific member from a list:

```ruby
gibbon.lists(list_id).members(lower_case_md5_hashed_email_address).actions.delete_permanent.create
```

### Tags

[Tags](https://mailchimp.com/help/getting-started-tags/) are a flexible way to organize (slice and dice) your list: for example, you can send a campaign directly to one or more tags.

Add tags to a subscriber:

```ruby
gibbon.lists(list_id).members(Digest::MD5.hexdigest(lower_case_email_address)).tags.create(
  body: {
    tags: [{name:"referred-from-xyz", status:"active"},{name:"pro-plan",status:"active"}]
  }
)
```


### Batch Operations

Any API call that can be made directly can also be organized into batch operations. Performing batch operations requires you to generate a hash for each individual API call and pass them as an `Array` to the Batch endpoint.

```ruby
# Create a new batch job that will create new list members
gibbon.batches.create(body: {
  operations: [
    {
      method: "POST",
      path: "lists/#{ list_id }/members",
      body: "{...}" # The JSON payload for PUT, POST, or PATCH
    },
    ...
  ]
})
```

This will create a new batch job and return a Batch response. The response will include an `id` attribute which can be used to check the status of a particular batch job.

##### Checking on a Batch Job
```ruby
gibbon.batches(batch_id).retrieve
```

###### Response Body (i.e. `response.body`)
```ruby
{
  "id"=>"0ca62e43cc",
  "status"=>"started",
  "total_operations"=>1,
  "finished_operations"=>1,
  "errored_operations"=>0,
  "submitted_at"=>"2016-04-19T01:16:58+00:00",
  "completed_at"=>"",
  "response_body_url"=>""
}
```

***Note*** This response truncated for brevity. Reference the MailChimp
[API documentation for Batch Operations](http://developer.mailchimp.com/documentation/mailchimp/reference/batches/) for more details.

### Fields

Only retrieve ids and names for fetched lists:

```ruby
gibbon.lists.retrieve(params: {"fields": "lists.id,lists.name"})
```

Only retrieve emails for fetched lists:

```ruby
gibbon.lists(list_id).members.retrieve(params: {"fields": "members.email_address"})
```

### Campaigns

Get first page of campaigns:

```ruby
campaigns = gibbon.campaigns.retrieve
```

Fetch the number of opens for a campaign

```ruby
email_stats = gibbon.reports(campaign_id).retrieve["opens"]
```

Create a new campaign:

```ruby
recipients = {
  list_id: list_id,
  segment_opts: {
    saved_segment_id: segment_id
  }
}
settings = {
  subject_line: "Subject Line",
  title: "Name of Campaign",
  from_name: "From Name",
  reply_to: "my@email.com"
}

body = {
  type: "regular",
  recipients: recipients,
  settings: settings
}

begin
  gibbon.campaigns.create(body: body)
rescue Gibbon::MailChimpError => e
  puts "Houston, we have a problem: #{e.message} - #{e.raw_body}"
end
```

Add content to a campaign:

*(Please note that Mailchimp does not currently support dynamic replacement of mc:edit areas in their drag-and-drop templates using their API.  Custom templates [can be used](http://stackoverflow.com/questions/29366766/mailchimp-api-not-replacing-mcedit-content-sections-using-ruby-library) instead.)*

```ruby
body = {
  template: {
    id: template_id,
    sections: {
      "name-of-mc-edit-area": "Content here"
    }
  }
}

gibbon.campaigns(campaign_id).content.upsert(body: body)
```

Send a campaign:

```ruby
gibbon.campaigns(campaign_id).actions.send.create
```

Schedule a campaign:

```ruby
body = {
  schedule_time: "2016-06-27 20:00:00"
}
```

```ruby
gibbon.campaigns(campaign_id).actions.schedule.create(body: body)
```

### Interests

Interests are a little more complicated than other parts of the API, so here's an example of how you would set interests during at subscription time or update them later. The ID of the interests you want to opt in or out of must be known ahead of time so an example of how to find interest IDs is also included.

Subscribing a member to a list with specific interests up front:

```ruby
gibbon.lists(list_id).members.create(body: {email_address: user_email_address, status: "subscribed", interests: {some_interest_id: true, another_interest_id: true}})
```

Updating a list member's interests:

```ruby
gibbon.lists(list_id).members(member_id).update(body: {interests: {some_interest_id: true, another_interest_id: false}})
```

So how do we get the interest IDs? When you query the API for a specific list member's information:

```ruby
gibbon.lists(list_id).members(member_id).retrieve
```

The response body (i.e. `response.body`) looks someting like this (unrelated things removed):

```ruby
{"id"=>"...", "email_address"=>"...", ..., "interests"=>{"3def637141"=>true, "f7cc4ee841"=>false, "fcdc951b9f"=>false, "3daf3cf27d"=>true, "293a3703ed"=>false, "72370e0d1f"=>false, "d434d21a1c"=>false, "bdb1ff199f"=>false, "a54e78f203"=>false, "c4527fd018"=>false} ...}
```

The API returns a map of interest ID to boolean value. Now we to get interest details so we know what these interest IDs map to. Looking at [this doc page](http://kb.mailchimp.com/api/resources/lists/interest-categories/interests/lists-interests-collection), we need to do this:

```ruby
gibbon.lists(list_id).interest_categories.retrieve
```

To get a list of interest categories. That gives us something like (again, this is the `response.body`):

```ruby
{"list_id"=>"...", "categories"=>[{"list_id"=>"...", "id"=>"0ace7aa498", "title"=>"Food Preferences", ...}] ...}
```

In this case, we're interested in the ID of the "Food Preferences" interest, which is `0ace7aa498`. Now we can fetch the details for this interest group:

```ruby
gibbon.lists(list_id).interest_categories("0ace7aa498").interests.retrieve
```

That response gives the interest data, including the ID for the interests themselves, which we can use to update a list member's interests or set them when we call the API to subscribe her or him to a list.

### Error handling

Gibbon raises an error when the API returns an error.

`Gibbon::MailChimpError` has the following attributes: `title`, `detail`, `body`, `raw_body`, `status_code`. Some or all of these may not be
available depending on the nature of the error. For example:

```ruby
begin
  gibbon.lists(list_id).members.create(body: body)
rescue Gibbon::MailChimpError => e
  puts "Houston, we have a problem: #{e.message} - #{e.raw_body}"
end
```

### Other

Overriding Gibbon's API endpoint (i.e. if using an access token from OAuth and have the `api_endpoint` from the [metadata](http://apidocs.mailchimp.com/oauth2/)):

```ruby
Gibbon::Request.api_endpoint = "https://us1.api.mailchimp.com"
Gibbon::Request.api_key = your_access_token_or_api_key
```

You can set an optional proxy url like this (or with an environment variable MAILCHIMP_PROXY):

```ruby
gibbon.proxy = 'http://your_proxy.com:80'
```

You can set a different [Faraday adapter](https://github.com/lostisland/faraday) during initialization:

```ruby
gibbon = Gibbon::Request.new(api_key: "your_api_key", faraday_adapter: :net_http)
```

### Migrating from Gibbon 1.x

Gibbon 2.x+ exposes a different API from version 1.x. This is because Gibbon maps to MailChimp's API and because version 3 of the API is quite different from version 2. First, the name of the primary class has changed from `API` to `Request`. And the way you pass an API key during initialization is different. A few examples below.

#### Initialization

Gibbon 1.x:

```ruby
gibbon = Gibbon::API.new("your_api_key")
```

Gibbon 2.x+:

```ruby
gibbon = Gibbon::Request.new(api_key: "your_api_key")
```

MailChimp API 3 is a RESTful API, so Gibbon's syntax now requires a trailing call to a verb, as described above.

#### Fetching Lists

Gibbon 1.x:

```ruby
gibbon.lists.list
```

Gibbon 2.x+:

```ruby
gibbon.lists.retrieve
```

#### Fetching List Members

Gibbon 1.x:

```ruby
gibbon.lists.members({:id => list_id})
```

Gibbon 2.x+:

```ruby
gibbon.lists(list_id).members.retrieve
```

#### Subscribing a Member to a List

Gibbon 1.x:

```ruby
gibbon.lists.subscribe({:id => list_id, :email => {:email => "foo@bar.com"}, :merge_vars => {:FNAME => "Bob", :LNAME => "Smith"}})
```

Gibbon 2.x+:

```ruby
gibbon.lists(list_id).members.create(body: {email_address: "foo@bar.com", status: "subscribed", merge_fields: {FNAME: "Bob", LNAME: "Smith"}})
```

## Thanks

Thanks to everyone who has [contributed](https://github.com/amro/gibbon/contributors) to Gibbon's development.

## Copyright

* Copyright (c) 2010-2022 Amro Mousa. See LICENSE.txt for details.
* MailChimp (c) 2001-2022 The Rocket Science Group.

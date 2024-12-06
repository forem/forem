---
sidebar_position: 2
title: CSV Export
---

Exporting to CSV

Example downloading a csv file preserving ransack search, based on [this gist](https://gist.github.com/pama/adff25ed1f4b796ce088ea362a08e1c5)

```ruby title='index.html.erb'
<h1>Users</h1>

<%= search_form_for @q, url: dashboard_index_path do |f| %>
  <%= f.label :name_cont %>
  <%= f.search_field :name_cont %>

  <%= f.submit %>
<% end %>

<ul>
  <% @users.each do |user| %>
    <li><%= user.name %> [<%= user.devices.map {|device| device.name }.join(', ') %>]</li>
  <% end %>
</ul>

<% if params[:q] %>
  <%= link_to 'Export 1', dashboard_index_path({name: params[:q][:name_cont]}.merge({format: :csv})) %>
<% else %>
  <%= link_to 'Export 2', dashboard_index_path(format: 'csv') %>
<% end %>
```

```ruby title='user.rb'
require 'csv'

class User < ApplicationRecord
  has_many :devices

  def self.get_csv(users)
    CSV.generate do |csv|
      csv << ["Name", "Devices"]

      users.each do |user|
        csv << [user.name, user.devices.map{|device| device.name}.join(', ')]
      end
    end
  end
end
```

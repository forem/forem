---
sidebar_position: 2
title: Advanced Mode
---


"Advanced" searches Rails's nested attributes functionality in order to
generate complex queries with nested AND/OR groupings, etc. This takes a bit
more work but can generate some pretty cool search interfaces that put a lot of
power in the hands of your users.

A notable drawback with these searches is
that the increased size of the parameter string will typically force you to use
the HTTP POST method instead of GET.


## Tweak your routes

```ruby
resources :people do
  collection do
    match 'search' => 'people#search', via: [:get, :post], as: :search
  end
end
```

## Add a controller action

```ruby
def search
  index
  render :index
end
```

## Update your form

```erb
<%= search_form_for @q, url: search_people_path,
                        html: { method: :post } do |f| %>
```

Once you've done so, you can make use of the helpers in [Ransack::Helpers::FormBuilder](https://github.com/activerecord-hackery/ransack/lib/ransack/helpers/form_builder.rb) to
construct much more complex search forms, such as the one on the
[demo app](http://ransack-demo.herokuapp.com/users/advanced_search)
(source code [here](https://github.com/activerecord-hackery/ransack_demo)).

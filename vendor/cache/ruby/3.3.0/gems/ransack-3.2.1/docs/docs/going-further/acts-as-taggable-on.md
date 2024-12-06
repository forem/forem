---
title: Acts-as-taggable-on
sidebar_position: 13
---

## Using Acts As Taggable On

If you have an `ActiveRecord` model and you're using [acts-as-taggable-on](https://github.com/mbleigh/acts-as-taggable-on),
chances are you might want to search on tagged fields. Follow the instructions to install the gem and then set up your project files.

### Configure the model

`app/models/tasks.rb`

You can call the tagging field anything you like, it just needs to be plural. No migration is needed as this is stored in the internal ActsAsTaggable tables (`tags` and `taggings`).

```ruby
class Task < ApplicationRecord
  acts_as_taggable_on :projects
end
```

### Controller

Add a field to strong params in the controller. Use the singular name with `_list`.

`app/controllers/tasks_controller.rb`

```ruby
def strong_params
  params
    .require(:tasks)
    .permit(:task, :example_field, :project_list)
```

### Form

We need to `send` the tag fieldname to our model, also using the singular naming.

```erb
<div class='form-group'>
  <%= f.label :project_list %>
  <%= f.text_field :project_list, value: @task.send(:project_list).to_s %>
 </div>
```

Now we can collect our data via the form, with tags separated by commas.

## Ransack Search

Imagine you have the following two instances of `Task`:

```ruby
{ id: 1, name: 'Clean up my room',        projects: [ 'Home', 'Personal' ] }
{ id: 2, name: 'Complete math exercises', projects: [ 'Homework', 'Study' ] }
```

When you're writing a `Ransack` search form, you can choose any of the following options:

```erb
<%= search_form_for @search do |f| %>
  <%= f.text_field :projects_name_in   %> <!-- option a -->
  <%= f.text_field :projects_name_eq   %> <!-- option b -->
  <%= f.text_field :projects_name_cont %> <!-- option c -->
<% end %>
```

### Option A - Match keys exactly

Option `a` will match keys exactly. This is the solution to choose if you want to distinguish 'Home' from 'Homework': searching for 'Home' will return just the `Task` with id 1. It also allows searching for more than one tag at once (comma separated):
- `Home, Personal` will return task 1
- `Home, Homework` will return task 1 and 2

### Option B - match key combinations

Option `b` will match all keys exactly. This is the solution if you wanna search for specific combinations of tags:
- `Home` will return nothing, as there is no Task with just the `Home` tag
- `Home, Personal` will return task 1

### Option C - match substrings

Option `c` is used to match substrings. This is useful when you don't care for the exact tag, but only for part of it:
- `Home` will return task 1 and 2 (`/Home/` matches both `"Home"` and `"Homework"`)

### Option D - select from a list of tags

In Option D we allow the user to select a list of valid tags and then search againt them. We use the plural name here.

```erb
<div class='form-group'>
  <%= f.label :projects_name, 'Project' %>
  <%= f.select :projects_name_in, ActsAsTaggableOn::Tag.distinct.order(:name).pluck(:name) %>
</div>
```

## Multitenancy 

ActsAsTaggableOn allows scoping of tags based on another field on the model. Suppose we have a `language` field on the model, as an effective second level key. We would adjust our model to look like this:

```ruby
class Task < ApplicationRecord
  acts_as_taggable_on :projects
  acts_as_taggable_tenant :language
end
```

The Ransack search is then filtered using the `for_tenant` method

```erb
<div class='form-group'>
  <%= f.label :projects_name, 'Project' %>
  <%= f.select :projects_name_in, ActsAsTaggableOn::Tag.for_tenant('fr').distinct.order(:name).pluck(:name) %>
</div>
      

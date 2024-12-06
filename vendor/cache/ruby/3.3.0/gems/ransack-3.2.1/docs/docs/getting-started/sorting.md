---
title: Sorting
---


# Sorting

## Sorting in the View

You can add a form to capture sorting and filtering options together.

```erb
<div class="filters" id="filtersSidebar">
  <header class="filters-header">
    <div class="filters-header-content">
      <h3>Filters</h3>
    </div>
  </header>

  <div class="filters-content">
    <%= search_form_for @q,
          class: 'form',
          url: articles_path,
          html: { autocomplete: 'off', autocapitalize: 'none' } do |f| %>

      <div class="form-group">
        <%= f.label :title_cont, t('Filter_by_keyword') %>
        <%= f.search_field :title_cont %>
      </div>

      <%= render partial: 'filters/date_title_sort', locals: { f: f } %>

      <div class="form-group">
        <%= f.label :grade_level_gteq, t('Grade_level') %> >=
        <%= f.search_field :grade_level_gteq  %>
      </div>

      <div class="form-group">
        <%= f.label :readability_gteq, t('Readability') %> >=
        <%= f.search_field :readability_gteq  %>
      </div>

      <div class="form-group">
        <i><%= @articles.total_count %> articles</i>
      </div>

      <div class="form-group">
        <hr/>
        <div class="filters-header-content">
          <%= link_to request.path, class: 'form-link' do %>
            <i class="far fa-undo icon-l"></i><%= t('Clear_all') %>
          <% end %>

          <%= f.submit t('Filter'), class: 'btn btn-primary' %>
        </div>
      </div>    
    <% end %>
  </div>
</div>
```


## Sorting in the Controller

To specify a default search sort field + order in the controller `index`:

```ruby
@search = Post.ransack(params[:q])
@search.sorts = 'name asc' if @search.sorts.empty?
@posts = @search.result.paginate(page: params[:page], per_page: 20)
```

Multiple sorts can be set by:

```ruby
@search = Post.ransack(params[:q])  
@search.sorts = ['name asc', 'created_at desc'] if @search.sorts.empty?
@posts = @search.result.paginate(page: params[:page], per_page: 20)
```

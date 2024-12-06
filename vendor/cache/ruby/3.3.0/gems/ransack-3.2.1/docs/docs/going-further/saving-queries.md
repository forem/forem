---
sidebar_position: 7
title: Saving queries
---

## Ransack Memory Gem

The [Ransack Memory](https://github.com/richardrails/ransack_memory) gem accomplishes this.

## Custom solution

If you want a custom solution, you can build it yourself. My ransack AJAX searching doesn’t save your search parameters across transactions. In this post I’ll show you how to easily add this capability in a generic way.

In this example I added AJAX search ability to index pages.

```ruby
def index
  @search = ComponentDefinition.search(search_params)
  # make name the default sort column
  @search.sorts = 'name' if @search.sorts.empty?
  @component_definitions = @search.result().page(params[:page])
end
```

I added methods(search_params, clear_search_index) in the ApplicationController to add a level of abstraction from the search gem I was using. Turns out this made things super easy, especially considering I won’t have to update my code generation tools for index pages.

```ruby
class ApplicationController < ActionController::Base
  def search_params
    params[:q]
  end
  def clear_search_index
    if params[:search_cancel]
      params.delete(:search_cancel)
      if(!search_params.nil?)
        search_params.each do |key, param|
          search_params[key] = nil
        end
      end
    end
  end
end
```

I decided to store the ransack search parameters, params[:q], in the session. To make the session parameter unique I used a key creed from the controllers name and “_search”.

```ruby
class ApplicationController < ActionController::Base

  # CHECK THE SESSION FOR SEARCH PARAMETERS IS THEY AREN'T IN THE REQUEST
  def search_params
    if params[:q] == nil
        params[:q] = session[search_key]
    end
    if params[:q]
          session[search_key] = params[:q]
        end
        params[:q]
  end
  # DELETE SEARCH PARAMETERS FROM THE SESSION
  def clear_search_index
      if params[:search_cancel]
        params.delete(:search_cancel)
        if(!search_params.nil?)
            search_params.each do |key, param|
                search_params[key] = nil
            end
        end
        # REMOVE FROM SESSION
        session.delete(search_key)
      end
  end

protected
  # GENERATE A GENERIC SESSION KEY BASED ON TEH CONTROLLER NAME
  def search_key
    "#{controller_name}_search".to_sym
  end
end
```

Based on [Saving queries](https://techbrownbags.wordpress.com/2015/02/18/rails-save-ransack-search-queries/)

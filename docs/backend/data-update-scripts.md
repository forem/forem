---
title: Data Update Scripts
---

## What are Data Update Scripts?

Data Update Scripts were introduced in
[this PR](https://github.com/forem/forem/pull/6025) and allow us to run any data
updates we might need. For example, if we added a column to the database and
then wanted to backfill that column with data, rather than going and manually
doing it in a console, we would use a DataUpdateScript. Another example might be
adding a new attribute to Elasticsearch. We could then use a DataUpdateScript to
reindex all of our models.

## How it works

First off, we added a
[DataUpdateScript model](https://github.com/forem/forem/blob/master/app/models/data_update_script.rb)
to Rails and a corresponding database table. This table is what we use to keep
track of what scripts have been run and which ones have not/still need to be.

To create a script you can use our custom Rails generator:

```
rails generate data_update BackfillColumnForArticles
```

This will create a simple Ruby class like below and all you have to do is fill
in the code it will run.

```ruby
module DataUpdateScripts
  class BackfillColumnForArticles
    def run
      # Place your data update logic here
      # Make sure your code is idempotent and can be run safely
      # multiple times at any time
    end
  end
end
```

The generator will also automatically create the corresponding spec file.

```ruby
require "rails_helper"
require Rails.root.join(
  "lib/data_updates/20201103042915_backfill_column_for_articles.rb",
)

describe DataUpdateScripts::BackfillColumnForArticles do
  pending "add some examples to (or delete) #{__FILE__}"
end
```

While we encourage adding tests for data update scripts, you can skip spec
creation by adding the `--no-spec` option to the `rails generate` command:

```
rails generate data_update BackfillColumnForArticles --no-spec
```

Once your script is in place then you can either run `rails data_updates:run`
manually or you can let our setup script handle it. In our local
[bin/setup](https://github.com/forem/forem/blob/main/bin/setup) script you will
see we have added an additional task to update data. This kicks off the rake
task `data_updates:run` for you.

The rake task itself will check the `lib/data_update_scripts` folder to see if
there are any new scripts that need to be run. It does this by reading all of
the files and then checking to see if they have a corresponding database entry.
If they do not, then we create a new one and run the script. If a database entry
already exists and it indicates the script has been run, then we skip that
script.

## In production

DataUpdateScripts are also run automatically when a production deploy goes out.
However, to ensure the new code they need to use has been deployed we use a
[`DataUpdateWorker`](https://github.com/forem/forem/blob/main/app/workers/data_update_worker.rb)
via Sidekiq and set it to run 10 minutes after the deploy script has completed.

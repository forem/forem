---
title: Approvals Tests
---

# Approvals Tests

Approvals test is a form of unit test. It works by taking a snapshot of the
results and confirming that they have not changed. A good use-case for the
Approvals tests is to compare the rendered HTML to the test specified HTML.

## Usage

Simply create your test similar to the following:

```ruby
it "renders the correct HTML on the home page" do
  page = '<html><head></head><body><h1>ZOMG</h1></body></html>'
  verify(format: :html) { page } # format can also be :json
end
```

You may then run the said test and a new `*.received.*` file will be created.
Thereafter, run the following command to verify the newly created file and
approve the created change.

```shell
approvals verify
```

Please be sure to include the Approvals file in your commit.

## Edge cases

Approvals tests are difficult to utilise for testing variables that change. This
includes variables like:

- Time
- URL slug
- uploaded image slug

Please avoid generating large approvals files as it will be stored in the
codebase. If your approvals file gets too large, Approvals test may not be the
right tool for the job.

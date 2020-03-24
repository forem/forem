---
title: Approvals Tests
---

# Approvals Tests

Approvals are based on the idea of the golden master. You take a snapshot of an
object and then compare all future versions of the object to the snapshot. A
good use-case for Approvals tests is comparing rendered HTML.

## Usage

Simply create your test similar to the following

```ruby
it "works" do
  page = '<html><head></head><body><h1>ZOMG</h1></body></html>'
  verify(format: :html) { page } # format can also be :json
end
```

then run the said test and a new `*.received.*` file will be created. You will
then run the following to verify the newly created file and approve the created
change.

```shell
approvals verify
```

Please be sure to include the Approvals file in your commit.

## Edge cases

Approvals test isn't great for testing changing variables. That includes

- Time
- URL slug
- uploaded image slug

Please avoid generating large approvals files as it will be stored in the
codebase. If your approvals file gets too large, Approvals test may not be the
right tool for the job.

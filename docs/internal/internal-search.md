---
title: Internal Search
---

# Internal Search

For internal views that need to take advantage of searching and filtering, we've
chosen to use [Ransack][ransack].

Ransack is a Ruby gem that makes searching relatively painless. It has excellent
documentation, but if you're looking for an example of how it's being used on
DEV, we've implemented it to help searching and sorting user reports.

The view responsible for managing user reports can be found at
`localhost:3000/internal/reports` and Ransack can be seen in use on the index
action of the [`internal/feedback_messages_controller`][feedback_messages].

For DEV, Ransack is being used exclusively in internal, for search problems in
other parts of the app we use [Algolia][algolia].

[feedback_messages]:
  https://github.com/thepracticaldev/dev.to/blob/4e41e4a2ac893fa2a6c36990cfe475858ffb086a/app/controllers/internal/feedback_messages_controller.rb#L4
[ransack]: https://github.com/activerecord-hackery/ransack
[algolia]: /backend/algolia

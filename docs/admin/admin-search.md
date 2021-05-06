---
title: Admin Search
---

# Admin Search

For admin views that need to take advantage of searching and filtering, we've
chosen to use [Ransack][ransack].

Ransack is a Ruby gem that makes searching relatively painless. It has excellent
documentation, but if you're looking for an example of how it's being used on
Forem, we've implemented it to help searching and sorting user reports.

The view responsible for managing user reports can be found at
`/admin/moderation/reports` and Ransack can be seen in use on the
index action of the [`admin/feedback_messages_controller`][feedback_messages].

For Forem, Ransack is being used exclusively in admin, for search problems in
other parts of the app we use [PostgreSQL Full Text Search][postgres_fts].

[feedback_messages]:
  https://github.com/forem/forem/blob/4e41e4a2ac893fa2a6c36990cfe475858ffb086a/app/controllers/admin/feedback_messages_controller.rb#L4
[ransack]: https://github.com/activerecord-hackery/ransack
[postgres_fts]: https://www.postgresql.org/docs/11/textsearch.html

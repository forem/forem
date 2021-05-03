---
title: Stack
---

## 🔑 Key App tech/services

For the Forem tech stack we use:

- [_Puma_](https://github.com/puma/puma) as the web server
- [_PostgreSQL_](https://www.postgresql.org/) as the primary database and for
  Full Text Search
- [_Redis_](https://redis.io/) to store cached data
- [_Fastly_](https://www.fastly.com/) for
  [edge caching](https://dev.to/ben/making-devto-insanely-fast)
- [_Cloudinary_](https://cloudinary.com/) and/or
  [_Imgproxy_](https://github.com/imgproxy/imgproxy) for image
  manipulation/serving
- [_Honeybadger_](https://www.honeybadger.io/) for error monitoring
- [_Sidekiq_](https://github.com/mperham/sidekiq) and
  [_Active Job_](https://guides.rubyonrails.org/active_job_basics.html) for
  background workers
- [Ransack](https://github.com/activerecord-hackery/ransack) for internal search
- [_Redcarpet_](https://github.com/vmg/redcarpet) and
  [_Rouge_](https://github.com/jneen/rouge) to parse Markdown
- [_Carrierwave_](https://github.com/carrierwaveuploader/carrierwave),
  [_Fog_](https://github.com/fog/fog-aws) and
  [_AWS S3_](https://aws.amazon.com/s3/) for image upload/storage
- [_InstantClick_](http://instantclick.io/) (a modified version) instead of
  _Turbolinks_ to accelerate navigation
- [_ImageMagick_](https://imagemagick.org/) to manipulate images on upload
- [_Heroku_](https://www.heroku.com) for hosting
- [_Sendgrid_](https://sendgrid.com/) for transactional mailing
- [_Mailchimp_](https://mailchimp.com/) for marketing/outreach emails
- [_CounterCulture_](https://github.com/magnusvk/counter_culture) to keep track
  of association counts (counter caches)
- [_Rolify_](https://github.com/RolifyCommunity/rolify) for role management
- [_Pundit_](https://github.com/varvet/pundit) for authorization to proxy
  traffic
- [Preact](https://preactjs.com/) for some of the frontend. See
  [the Frontend Guide](/frontend) for more info
- [_Pusher_](https://pusher.com) for realtime communication between the
  application and users' browsers
- [_GitDocs_](https://github.com/timberio/gitdocs) for beautiful and
  SEO-friendly documentation
- [Git](https://git-scm.com/) for version control
- [GitHub](https://github.com/) for hosting the source code and issue tracking

_This list is non-exhaustive. If you see something that belongs here, feel free
to add it._

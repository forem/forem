---
title: Technical Overview
---

## 🔑 Key App tech/services

- We use [_Puma_](https://github.com/puma/puma) as the web server
- We [rely heavily on edge caching](https://dev.to/ben/making-devto-insanely-fast) with [_Fastly_](https://www.fastly.com/)
- We use [_Cloudinary_](https://cloudinary.com/) for image manipulation/serving
- We use [_Airbrake_](https://airbrake.io/) for error monitoring
- We use [_Timber_](https://timber.io/) for logging
- We use [_Delayed Job_](https://github.com/collectiveidea/delayed_job) and [_Active Job_](https://guides.rubyonrails.org/active_job_basics.html) for background workers
- We use [_Algolia_](https://www.algolia.com/) for search
- We use [_Redcarpet_](https://github.com/vmg/redcarpet) and [_Rouge_](https://github.com/jneen/rouge) to parse Markdown
- We use [_Carrierwave_](https://github.com/carrierwaveuploader/carrierwave), [_Fog_](https://github.com/fog/fog-aws) and [_AWS S3_](https://aws.amazon.com/s3/) for image upload/storage
- We use a modified version of [_InstantClick_](http://instantclick.io/) instead of _Turbolinks_ to accelerate navigation
- We are hosted on [_Heroku_](https://www.heroku.com)
- We use [_Heroku scheduler_](https://devcenter.heroku.com/articles/scheduler) for scheduled jobs
- We use [_Sendgrid_](https://sendgrid.com/) for transactional mailing
- We use [_Mailchimp_](https://mailchimp.com/) for marketing/outreach emails
- We use [_Figaro_](https://github.com/laserlemon/figaro) for app configuration.
- We use [_CounterCulture_](https://github.com/magnusvk/counter_culture) to keep track of association counts (counter caches)
- We use [_Rolify_](https://github.com/RolifyCommunity/rolify) for role management.
- We use [_Pundit_](https://github.com/varvet/pundit) for authorization.
- We use [_Service Workers_](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API/Using_Service_Workers) to proxy traffic
- We use [Preact](https://preactjs.com/) for some of the frontend. See [the Frontend Guide](/frontend) for more info
- We use [_Pusher_](https://pusher.com) for realtime communication between the application and users' browsers.
- We use [_GitDocs_](https://gitdocs.netlify.com) for beautiful and SEO-friendly documentation
- We use [Git](https://git-scm.com/) for version control.
- We use [GitHub](https://github.com/) for hosting the source code and issue tracking.

_This list is non-exhaustive. If you see something that belongs here, feel free to add it._

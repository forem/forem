## 🔑 Key App tech/services

- We use [_Puma_](https://github.com/puma/puma) for the server
- We [rely heavily on edge caching](https://dev.to/ben/making-devto-insanely-fast) with _Fastly_
- We use _Cloudinary_ for image manipulation/serving
- We use _Airbrake_ for error monitoring
- We use _Timber_ for logging
- We use [_Delayed Job_](https://github.com/collectiveidea/delayed_job) for background workers
- We use _Algolia_ for search
- We use [_Redcarpet_](https://github.com/vmg/redcarpet) and [_Rouge_](https://github.com/jneen/rouge) for Markdown
- We use _[Carrierwave](https://github.com/carrierwaveuploader/carrierwave)/Fog/AWS S3_ for image upload/storage
- We use a modified version of [_InstantClick_](http://instantclick.io/) instead of _Turbolinks_
- We are hosted on _Heroku_
- We use _Heroku scheduler_ for scheduled jobs (default)
- We use _Sendgrid_ for API-triggered mailing
- We use _Mailchimp_ for marketing/outreach emails
- We use [_Figaro_](https://github.com/laserlemon/figaro) for app configuration.
- We use [_CounterCulture_](https://github.com/magnusvk/counter_culture) to keep track of association counts (counter caches)
- We use [_Rolify_](https://github.com/RolifyCommunity/rolify) for role management.
- We use [_Pundit_](https://github.com/varvet/pundit) for authorization.
- We use Service Workers to proxy traffic
- We use Preact for some of the front end. See [Frontend](https://docs.dev.to/frontend/) for more info
- We use [_Pusher_](https://pusher.com) for realtime communication between the application and users’ browsers.

_This list is non-exhaustive. If you see something that belongs here, feel free to add it._

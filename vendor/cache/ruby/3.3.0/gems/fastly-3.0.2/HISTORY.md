# HEAD

## 2015-02-05 v1.2.0
* remove curb-fu. Net::HTTP is used instead - https://github.com/fastly/fastly-ruby/pull/44
* better client error handling - https://github.com/fastly/fastly-ruby/pull/48

## 2014-12-15 v1.1.5
* major refactor and reorganization of code (merged branch https://github.com/fastly/fastly-ruby/pull/31)
* bump curb dep to 0.8.6 for ruby 2.1 support (see https://github.com/fastly/fastly-ruby/issues/43)

2014-09-29 v1.1.4
* Require API Key for purge by key requests

2014-07-25 v1.1.3
* Add test:unit rake task
* Add Rubocop and some rubocop cleanup
* Clarify gem name in documentation
* Fix a bug in the `Fastly.get_options` method
* Add `bin/fastly_create_domain` script to easily create domain

2014-06-12 v1.1.2
* Replace `String#underscore` with `Fastly::Util.class_to_path` method.
* Add first true unit test
* Add `test_helper.rb`
* Add `pry` as dependency
* Add console Rake task

2013-11-26 v1.02

Fix rdoc dependency and quorum spelling (Kristoffer Renholm)

2013-10-03 v1.01

Add historical stats functionality
Fix settings
Add conditions
Add in auto_loadbalancing for backends
Fix some doc stuff (Sam Sharpe)
Reorganize library (Eric Saxby & Paul Henry)
Fix purge_all, purge_by_key and details (Kazuki Ohta)

2013-07-16 v1.00

Fix delete VCL (thanks Andrian Jardan)

2012-05-01 v0.99

Fix some SSL issues
Allow some admin functionality

2012-02-02 v0.98

Make deactivate! work
Add active?
Add Service.purge_by_key

2012-01-27 v0.97

Fix invoice tests with new billing API

2012-01-16 v0.96

Fix version.locked?
Make fastly_upload_vcl work

2011-12-19 v0.95

Fix the way invoices and stats are fetched

2011-12-15 v0.9

Add mapping from backends to directors and directors to origins

2011-11-03 v0.8

Add list_* to all objects

Add Healthchecks and Syslog endpoint streaming

2011-11-02 v0.5

Initial releasee

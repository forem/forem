### 3.1.0.rc3 (pre-release 2021-07-14)

- [#785](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/785): `Stripe::Product` no longer requires `type`. [@TastyPi](https://github.com/TastyPi)
- [#784](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/784): Fix "Wrong number of arguments" error in tests. [@TastyPi](https://github.com/TastyPi)
- [#782](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/782): Support expanding `setup_intent` in `Stripe::Checkout::Session`. [@TastyPi](https://github.com/TastyPi)

### 3.1.0.rc2 (pre-release 2021-03-03)

- [#767](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/767): Fixes tests and more [@lpsBetty](https://github.com/lpsBetty)

### 3.1.0.rc1 (pre-release 2021-02-17)

- [#765](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/765): Properly set the status of a trialing subscription. [@csalvato](https://github.com/csalvato)
- [#764](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/764): Fixes erroneous error message when fetching upcoming invoices. [@csalvato](https://github.com/csalvato)
- [#762](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/762): Support Stripe Connect with Customers by adding stripe_account header namespace for customer object [@csalvato](https://github.com/csalvato)
- [#755](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/755): Add allowed params to subscriptions [@dominikdarnel ](https://github.com/dominikdarnel)
- [#748](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/758): Support Prices - [@hidenba](https://github.com/hidenba) and [@jamesprior](https://github.com/jamesprior).
- [#747](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/747/files): Fix ruby 2.7 deprecation warnings. Adds Ruby 3.0.0 compatibility. [@coding-chimp](https://github.com/coding-chimp)
- [#715](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/715): Added application_fee_amount to mock charge object - [@espen](https://github.com/espen)
- [#709](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/709): Remove unnecessary check on customer's currency - [@coorasse](https://github.com/coorasse)

### 3.0.1 (TBD)

- Added Changelog file
- [#640](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/640): Support Payment Intent status requires_capture - [@theodorton](https://github.com/theodorton).
- [#685](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/685): Adds support for pending_invoice_item_interval - [@joshcass](https://github.com/joshcass).
- [#682](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/682): Prevent customer metadata from being overwritten with each update - [@sethkrasnianski](https://github.com/sethkrasnianski).
- [#679](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/679): Fix for [#678](https://github.com/stripe-ruby-mock/stripe-ruby-mock/issues/678) Add active filter to Data::List - [@rnmp](https://github.com/rnmp).
- [#668](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/668): Fix for [#665](https://github.com/stripe-ruby-mock/stripe-ruby-mock/issues/665) Allow to remove discount from customer - [@mnin](https://github.com/mnin).
- [#667](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/667):
  Remove empty and duplicated methods from payment methods - [@mnin](https://github.com/mnin).
- [#664](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/664): Bugfix: pass through PaymentIntent amount to mocked Charge - [@typeoneerror](https://github.com/typeoneerror).
- [#654](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/654): fix for [#626](https://github.com/stripe-ruby-mock/stripe-ruby-mock/issues/626) Added missing decline codes - [@iCreateJB](https://github.com/iCreateJB).
- [#648](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/648): Initial implementation of checkout session API - [@fauxparse](https://github.com/fauxparse).
- [#644](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/644): Allow payment_behavior attribute on subscription create - [@j15e](https://github.com/j15e).

### 3.0.0 (2019-12-17)

##### the main thing is:

- [#658](https://github.com/stripe-ruby-mock/stripe-ruby-mock/pull/658) Make the gem compatible with Stripe Gem v.5

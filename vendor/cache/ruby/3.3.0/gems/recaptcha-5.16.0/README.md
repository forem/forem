
# reCAPTCHA
[![Gem Version](https://badge.fury.io/rb/recaptcha.svg)](https://badge.fury.io/rb/recaptcha)

Author:    Jason L Perry (http://ambethia.com)<br/>
Copyright: Copyright (c) 2007-2013 Jason L Perry<br/>
License:   [MIT](http://creativecommons.org/licenses/MIT/)<br/>
Info:      https://github.com/ambethia/recaptcha<br/>
Bugs:      https://github.com/ambethia/recaptcha/issues<br/>

This gem provides helper methods for the [reCAPTCHA API](https://www.google.com/recaptcha). In your
views you can use the `recaptcha_tags` method to embed the needed javascript, and you can validate
in your controllers with `verify_recaptcha` or `verify_recaptcha!`, which raises an error on
failure.


# Table of Contents
1. [Obtaining a key](#obtaining-a-key)
2. [Rails Installation](#rails-installation)
3. [Sinatra / Rack / Ruby Installation](#sinatra--rack--ruby-installation)
4. [reCAPTCHA V2 API & Usage](#recaptcha-v2-api-and-usage)
  - [`recaptcha_tags`](#recaptcha_tags)
  - [`verify_recaptcha`](#verify_recaptcha)
  - [`invisible_recaptcha_tags`](#invisible_recaptcha_tags)
5. [reCAPTCHA V3 API & Usage](#recaptcha-v3-api-and-usage)
  - [`recaptcha_v3`](#recaptcha_v3)
  - [`verify_recaptcha` (use with v3)](#verify_recaptcha-use-with-v3)
  - [`recaptcha_reply`](#recaptcha_reply)
6. [I18n Support](#i18n-support)
7. [Testing](#testing)
8. [Alternative API Key Setup](#alternative-api-key-setup)

## Obtaining a key

Go to the [reCAPTCHA admin console](https://www.google.com/recaptcha/admin) to obtain a reCAPTCHA API key.

The reCAPTCHA type(s) that you choose for your key will determine which methods to use below.

| reCAPTCHA type                               | Methods to use | Description |
|----------------------------------------------|----------------|-------------|
| v3                                           | [`recaptcha_v3`](#recaptcha_v3)                         | Verify requests with a [score](https://developers.google.com/recaptcha/docs/v3#score)
| v2 Checkbox<br/>("I'm not a robot" Checkbox) | [`recaptcha_tags`](#recaptcha_tags)                     | Validate requests with the "I'm not a robot" checkbox |
| v2 Invisible<br/>(Invisible reCAPTCHA badge) | [`invisible_recaptcha_tags`](#invisible_recaptcha_tags) | Validate requests in the background |

Note: You can _only_ use methods that match your key's type. You cannot use v2 methods with a v3
key or use `recaptcha_tags` with a v2 Invisible key, for example. Otherwise you will get an
error like "Invalid key type" or "This site key is not enabled for the invisible captcha."

Note: Enter `localhost` or `127.0.0.1` as the domain if using in development with `localhost:3000`.

## Rails Installation

**If you are having issues with Rails 7, Turbo, and Stimulus, make sure to check [this Wiki page](https://github.com/ambethia/recaptcha/wiki/Recaptcha-with-Turbo-and-Stimulus)!**

```ruby
gem "recaptcha"
```

You can keep keys out of the code base with environment variables or with Rails [secrets](https://api.rubyonrails.org/classes/Rails/Application.html#method-i-secrets).<br/>

In development, you can use the [dotenv](https://github.com/bkeepers/dotenv) gem. (Make sure to add it above `gem 'recaptcha'`.)

See [Alternative API key setup](#alternative-api-key-setup) for more ways to configure or override
keys. See also the
[Configuration](https://www.rubydoc.info/github/ambethia/recaptcha/master/Recaptcha/Configuration)
documentation.

```shell
export RECAPTCHA_SITE_KEY   = '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyy'
export RECAPTCHA_SECRET_KEY = '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxx'
```

If you have an Enterprise API key:

```shell
export RECAPTCHA_ENTERPRISE            = 'true'
export RECAPTCHA_ENTERPRISE_API_KEY    = 'AIzvFyE3TU-g4K_Kozr9F1smEzZSGBVOfLKyupA'
export RECAPTCHA_ENTERPRISE_PROJECT_ID = 'my-project'
```

Add `recaptcha_tags` to the forms you want to protect:

```erb
<%= form_for @foo do |f| %>
  # …
  <%= recaptcha_tags %>
  # …
<% end %>
```

Then, add `verify_recaptcha` logic to each form action that you've protected:

```ruby
# app/controllers/users_controller.rb
@user = User.new(params[:user].permit(:name))
if verify_recaptcha(model: @user) && @user.save
  redirect_to @user
else
  render 'new'
end
```
Please note that this setup uses [`reCAPTCHA_v2`](#recaptcha-v2-api-and-usage). For a `recaptcha_v3` use, please refer to [`reCAPTCHA_v3 setup`](#examples).

## Sinatra / Rack / Ruby installation

See [sinatra demo](/demo/sinatra) for details.

 - add `gem 'recaptcha'` to `Gemfile`
 - set env variables
 - `include Recaptcha::Adapters::ViewMethods` where you need `recaptcha_tags`
 - `include Recaptcha::Adapters::ControllerMethods` where you need `verify_recaptcha`


## reCAPTCHA v2 API and Usage

### `recaptcha_tags`

Use this when your key's reCAPTCHA type is "v2 Checkbox".

The following options are available:

| Option              | Description |
|---------------------|-------------|
| `:theme`            | Specify the theme to be used per the API. Available options: `dark` and `light`. (default: `light`) |
| `:ajax`             | Render the dynamic AJAX captcha per the API. (default: `false`) |
| `:site_key`         | Override site API key from configuration |
| `:error`            | Override the error code returned from the reCAPTCHA API (default: `nil`) |
| `:size`             | Specify a size (default: `nil`) |
| `:nonce`            | Optional. Sets nonce attribute for script. Can be generated via `SecureRandom.base64(32)`. (default: `nil`) |
| `:id`               | Specify an html id attribute (default: `nil`) |
| `:callback`         | Optional. Name of success callback function, executed when the user submits a successful response |
| `:expired_callback` | Optional. Name of expiration callback function, executed when the reCAPTCHA response expires and the user needs to re-verify. |
| `:error_callback`   | Optional. Name of error callback function, executed when reCAPTCHA encounters an error (e.g. network connectivity) |
| `:noscript`         | Include `<noscript>` content (default: `true`)|

[JavaScript resource (api.js) parameters](https://developers.google.com/recaptcha/docs/invisible#js_param):

| Option              | Description |
|---------------------|-------------|
| `:onload`           | Optional. The name of your callback function to be executed once all the dependencies have loaded. (See [explicit rendering](https://developers.google.com/recaptcha/docs/display#explicit_render)) |
| `:render`           | Optional. Whether to render the widget explicitly. Defaults to `onload`, which will render the widget in the first g-recaptcha tag it finds. (See [explicit rendering](https://developers.google.com/recaptcha/docs/display#explicit_render)) |
| `:hl`               | Optional. Forces the widget to render in a specific language. Auto-detects the user's language if unspecified. (See [language codes](https://developers.google.com/recaptcha/docs/language)) |
| `:script`           | Alias for `:external_script`. If you do not need to add a script tag by helper you can set the option to `false`. It's necessary when you add a script tag manualy (default: `true`). |
| `:external_script`  | Set to `false` to avoid including a script tag for the external `api.js` resource. Useful when including multiple `recaptcha_tags` on the same page. |
| `:script_async`     | Set to `false` to load the external `api.js` resource synchronously. (default: `true`) |
| `:script_defer`     | Set to `true` to defer loading of external `api.js` until HTML documen has been parsed. (default: `true`) |

Any unrecognized options will be added as attributes on the generated tag.

You can also override the html attributes for the sizes of the generated `textarea` and `iframe`
elements, if CSS isn't your thing. Inspect the [source of `recaptcha_tags`](https://github.com/ambethia/recaptcha/blob/master/lib/recaptcha/helpers.rb)
to see these options.

Note that you cannot submit/verify the same response token more than once or you will get a
`timeout-or-duplicate` error code. If you need reset the captcha and generate a new response token,
then you need to call `grecaptcha.reset()`.

### `verify_recaptcha`

This method returns `true` or `false` after processing the response token from the reCAPTCHA widget.
This is usually called from your controller, as seen [above](#rails-installation).

Passing in the ActiveRecord object via `model: object` is optional. If you pass a `model`—and the
captcha fails to verify—an error will be added to the object for you to use (available as
`object.errors`).

Why isn't this a model validation? Because that violates MVC. You can use it like this, or how ever
you like.

Some of the options available:

| Option                    | Description |
|---------------------------|-------------|
| `:model`                  | Model to set errors.
| `:attribute`              | Model attribute to receive errors. (default: `:base`)
| `:message`                | Custom error message.
| `:secret_key`             | Override the secret API key from the configuration.
| `:enterprise_api_key`     | Override the Enterprise API key from the configuration.
| `:enterprise_project_id ` | Override the Enterprise project ID from the configuration.
| `:timeout`                | The number of seconds to wait for reCAPTCHA servers before give up. (default: `3`)
| `:response`               | Custom response parameter. (default: `params['g-recaptcha-response-data']`)
| `:hostname`               | Expected hostname or a callable that validates the hostname, see [domain validation](https://developers.google.com/recaptcha/docs/domain_validation) and [hostname](https://developers.google.com/recaptcha/docs/verify#api-response) docs. (default: `nil`, but can be changed by setting `config.hostname`)
| `:env`                    | Current environment. The request to verify will be skipped if the environment is specified in configuration under `skip_verify_env`
| `:json`                   | Boolean; defaults to false; if true, will submit the verification request by POST with the request data in JSON


### `invisible_recaptcha_tags`

Use this when your key's reCAPTCHA type is "v2 Invisible".

For more information, refer to: [Invisible reCAPTCHA](https://developers.google.com/recaptcha/docs/invisible).

This is similar to `recaptcha_tags`, with the following additional options that are only available
on `invisible_recaptcha_tags`:

| Option              | Description |
|---------------------|-------------|
| `:ui`               | The type of UI to render for this "invisible" widget. (default: `:button`)<br/>`:button`: Renders a `<button type="submit">` tag with `options[:text]` as the button text.<br/>`:invisible`: Renders a `<div>` tag.<br/>`:input`: Renders a `<input type="submit">` tag with `options[:text]` as the button text. |
| `:text`             | The text to show for the button. (default: `"Submit"`)
| `:inline_script`    | If you do not need this helper to add an inline script tag, you can set the option to `false` (default: `true`).

It also accepts most of the options that `recaptcha_tags` accepts, including the following:

| Option              | Description |
|---------------------|-------------|
| `:site_key`         | Override site API key from configuration |
| `:nonce`            | Optional. Sets nonce attribute for script tag. Can be generated via `SecureRandom.base64(32)`. (default: `nil`) |
| `:id`               | Specify an html id attribute (default: `nil`) |
| `:script`           | Same as setting both `:inline_script` and `:external_script`. If you only need one or the other, use `:inline_script` and `:external_script` instead. |
| `:callback`         | Optional. Name of success callback function, executed when the user submits a successful response |
| `:expired_callback` | Optional. Name of expiration callback function, executed when the reCAPTCHA response expires and the user needs to re-verify. |
| `:error_callback`   | Optional. Name of error callback function, executed when reCAPTCHA encounters an error (e.g. network connectivity) |

[JavaScript resource (api.js) parameters](https://developers.google.com/recaptcha/docs/invisible#js_param):

| Option              | Description |
|---------------------|-------------|
| `:onload`           | Optional. The name of your callback function to be executed once all the dependencies have loaded. (See [explicit rendering](https://developers.google.com/recaptcha/docs/display#explicit_render)) |
| `:render`           | Optional. Whether to render the widget explicitly. Defaults to `onload`, which will render the widget in the first g-recaptcha tag it finds. (See [explicit rendering](https://developers.google.com/recaptcha/docs/display#explicit_render)) |
| `:hl`               | Optional. Forces the widget to render in a specific language. Auto-detects the user's language if unspecified. (See [language codes](https://developers.google.com/recaptcha/docs/language)) |
| `:external_script`  | Set to `false` to avoid including a script tag for the external `api.js` resource. Useful when including multiple `recaptcha_tags` on the same page. |
| `:script_async`     | Set to `false` to load the external `api.js` resource synchronously. (default: `true`) |
| `:script_defer`     | Set to `false` to defer loading of external `api.js` until HTML documen has been parsed. (default: `true`) |

### With a single form on a page

1. The `invisible_recaptcha_tags` generates a submit button for you.

```erb
<%= form_for @foo do |f| %>
  # ... other tags
  <%= invisible_recaptcha_tags text: 'Submit form' %>
<% end %>
```

Then, add `verify_recaptcha` to your controller as seen [above](#rails-installation).

### With multiple forms on a page

1. You will need a custom callback function, which is called after verification with Google's reCAPTCHA service. This callback function must submit the form. Optionally, `invisible_recaptcha_tags` currently implements a JS function called `invisibleRecaptchaSubmit` that is called when no `callback` is passed. Should you wish to override `invisibleRecaptchaSubmit`, you will need to use `invisible_recaptcha_tags script: false`, see lib/recaptcha/client_helper.rb for details.
2. The `invisible_recaptcha_tags` generates a submit button for you.

```erb
<%= form_for @foo, html: {id: 'invisible-recaptcha-form'} do |f| %>
  # ... other tags
  <%= invisible_recaptcha_tags callback: 'submitInvisibleRecaptchaForm', text: 'Submit form' %>
<% end %>
```

```javascript
// app/assets/javascripts/application.js
var submitInvisibleRecaptchaForm = function () {
  document.getElementById("invisible-recaptcha-form").submit();
};
```

Finally, add `verify_recaptcha` to your controller as seen [above](#rails-installation).

### Programmatically invoke

1. Specify `ui` option

```erb
<%= form_for @foo, html: {id: 'invisible-recaptcha-form'} do |f| %>
  # ... other tags
  <button type="button" id="submit-btn">
    Submit
  </button>
  <%= invisible_recaptcha_tags ui: :invisible, callback: 'submitInvisibleRecaptchaForm' %>
<% end %>
```

```javascript
// app/assets/javascripts/application.js
document.getElementById('submit-btn').addEventListener('click', function (e) {
  // do some validation
  if(isValid) {
    // call reCAPTCHA check
    grecaptcha.execute();
  }
});

var submitInvisibleRecaptchaForm = function () {
  document.getElementById("invisible-recaptcha-form").submit();
};
```


## reCAPTCHA v3 API and Usage

The main differences from v2 are:
1. you must specify an [action](https://developers.google.com/recaptcha/docs/v3#actions) in both frontend and backend
1. you can choose the minimum score required for you to consider the verification a success
   (consider the user a human and not a robot)
1. reCAPTCHA v3 is invisible (except for the reCAPTCHA badge) and will never interrupt your users;
   you have to choose which scores are considered an acceptable risk, and choose what to do (require
   two-factor authentication, show a v3 challenge, etc.) if the score falls below the threshold you
   choose

For more information, refer to the [v3 documentation](https://developers.google.com/recaptcha/docs/v3).

### Examples

With v3, you can let all users log in without any intervention at all if their score is above some
threshold, and only show a v2 checkbox recaptcha challenge (fall back to v2) if it is below the
threshold:

```erb
  …
  <% if @show_checkbox_recaptcha %>
    <%= recaptcha_tags %>
  <% else %>
    <%= recaptcha_v3(action: 'login', site_key: ENV['RECAPTCHA_SITE_KEY_V3']) %>
  <% end %>
  …
```

```ruby
# app/controllers/sessions_controller.rb
def create
  success = verify_recaptcha(action: 'login', minimum_score: 0.5, secret_key: ENV['RECAPTCHA_SECRET_KEY_V3'])
  checkbox_success = verify_recaptcha unless success
  if success || checkbox_success
    # Perform action
  else
    if !success
      @show_checkbox_recaptcha = true
    end
    render 'new'
  end
end
```

(You can also find this [example](demo/rails/app/controllers/v3_captchas_controller.rb) in the demo app.)

Another example:

```erb
<%= form_for @user do |f| %>
  …
  <%= recaptcha_v3(action: 'registration') %>
  …
<% end %>
```

```ruby
# app/controllers/users_controller.rb
def create
  @user = User.new(params[:user].permit(:name))
  recaptcha_valid = verify_recaptcha(model: @user, action: 'registration')
  if recaptcha_valid
    if @user.save
      redirect_to @user
    else
      render 'new'
    end
  else
    # Score is below threshold, so user may be a bot. Show a challenge, require multi-factor
    # authentication, or do something else.
    render 'new'
  end
end
```


### `recaptcha_v3`

Adds an inline script tag that calls `grecaptcha.execute` for the given `site_key` and `action` and
calls the `callback` with the resulting response token. You need to verify this token with
[`verify_recaptcha`](#verify_recaptcha-use-with-v3) in your controller in order to get the
[score](https://developers.google.com/recaptcha/docs/v3#score).

By default, this inserts a hidden `<input type="hidden" class="g-recaptcha-response">` tag. The
value of this input will automatically be set to the response token (by the default callback
function). This lets you include `recaptcha_v3` within a `<form>` tag and have it automatically
submit the token as part of the form submission.

Note: reCAPTCHA actually already adds its own hidden tag, like `<textarea
id="g-recaptcha-response-data-100000" name="g-recaptcha-response-data" class="g-recaptcha-response">`,
immediately ater the reCAPTCHA badge in the bottom right of the page — but since it is not inside of
any `<form>` element, and since it already passes the token to the callback, this hidden `textarea`
isn't helpful to us.

If you need to submit the response token to the server in a different way than via a regular form
submit, such as via [Ajax](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest) or [`fetch`](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API),
then you can either:
1. just extract the token out of the hidden `<input>` or `<textarea>` (both of which will have a
   predictable name/id), like `document.getElementById('g-recaptcha-response-data-my-action').value`, or
2. write and specify a custom `callback` function. You may also want to pass `element: false` if you
   don't have a use for the hidden input element.

Note that you cannot submit/verify the same response token more than once or you
will get a `timeout-or-duplicate` error code. If you need reset the captcha and
generate a new response token, then you need to call `grecaptcha.execute(…)` or
`grecaptcha.enterprise.execute(…)` again. This helper provides a JavaScript
method (for each action) named `executeRecaptchaFor{action}` to make this
easier. That is the same method that is invoked immediately. It simply calls
`grecaptcha.execute` or `grecaptcha.enterprise.execute` again and then calls the
`callback` function with the response token.

You will also get a `timeout-or-duplicate` error if too much time has passed between getting the
response token and verifying it. This can easily happen with large forms that take the user a couple
minutes to complete. Unlike v2, where you can use the `expired-callback` to be notified when the
response expires, v3 appears to provide no such callback. See also
[1](https://github.com/google/recaptcha/issues/281) and
[2](https://stackoverflow.com/questions/54437745/recaptcha-v3-how-to-deal-with-expired-token-after-idle).

To deal with this, it is recommended to call the "execute" in your form's submit handler (or
immediately before sending to the server to verify if not using a form) rather than using the
response token that gets generated when the page first loads. The `executeRecaptchaFor{action}`
function mentioned above can be used if you want it to invoke a callback, or the
`executeRecaptchaFor{action}Async` variant if you want a `Promise` that you can `await`. See
[demo/rails/app/views/v3_captchas/index.html.erb](demo/rails/app/views/v3_captchas/index.html.erb)
for an example of this.

This helper is similar to the [`recaptcha_tags`](#recaptcha_tags)/[`invisible_recaptcha_tags`](#invisible_recaptcha_tags) helpers
but only accepts the following options:

| Option              | Description |
|---------------------|-------------|
| `:site_key`         | Override site API key |
| `:action`           | The name of the [reCAPTCHA action](https://developers.google.com/recaptcha/docs/v3#actions). Actions are not case-sensitive and may only contain alphanumeric characters, slashes, and underscores, and must not be user-specific. |
| `:nonce`            | Optional. Sets nonce attribute for script. Can be generated via `SecureRandom.base64(32)`. (default: `nil`) |
| `:callback`         | Name of callback function to call with the token. When `element` is `:input`, this defaults to a function named `setInputWithRecaptchaResponseTokenFor#{sanitize_action(action)}` that sets the value of the hidden input to the token. |
| `:id`               | Specify a unique `id` attribute for the `<input>` element if using `element: :input`. (default: `"g-recaptcha-response-data-"` + `action`) |
| `:name`             | Specify a unique `name` attribute for the `<input>` element if using `element: :input`. (default: `g-recaptcha-response-data[action]`) |
| `:script`           | Same as setting both `:inline_script` and `:external_script`. (default: `true`). |
| `:inline_script`    | If `true`, adds an inline script tag that calls `grecaptcha.execute` for the given `site_key` and `action` and calls the `callback` with the resulting response token. Pass `false` if you want to handle calling `grecaptcha.execute` yourself. (default: `true`) |
| `:element`          | The element to render, if any (default: `:input`)<br/>`:input`: Renders a hidden `<input type="hidden">` tag. The value of this will be set to the response token by the default `setInputWithRecaptchaResponseTokenFor{action}` callback.<br/>`false`: Doesn't render any tag. You'll have to add a custom callback that does something with the token. |
| `:turbo`              | If `true`, calls the js function which executes reCAPTCHA after all the dependencies have been loaded. This cannot be used with the js param `:onload`. This makes reCAPTCHAv3 usable with turbo. |
| `:turbolinks`         | Alias of `:turbo`. Will be deprecated soon. |
| `:ignore_no_element`  | If `true`, adds null element checker for forms that can be removed from the page by javascript like modals with forms. (default: true) |

[JavaScript resource (api.js) parameters](https://developers.google.com/recaptcha/docs/invisible#js_param):

| Option              | Description |
|---------------------|-------------|
| `:onload`           | Optional. The name of your callback function to be executed once all the dependencies have loaded. (See [explicit rendering](https://developers.google.com/recaptcha/docs/display#explicit_render))|
| `:external_script`  | Set to `false` to avoid including a script tag for the external `api.js` resource. Useful when including multiple `recaptcha_tags` on the same page.
| `:script_async`     | Set to `true` to load the external `api.js` resource asynchronously. (default: `false`) |
| `:script_defer`     | Set to `true` to defer loading of external `api.js` until HTML documen has been parsed. (default: `false`) |

If using `element: :input`, any unrecognized options will be added as attributes on the generated
`<input>` element.

### `verify_recaptcha` (use with v3)

This works the same as for v2, except that you may pass an `action` and `minimum_score` if you wish
to validate that the action matches or that the score is above the given threshold, respectively.

```ruby
result = verify_recaptcha(action: 'action/name')
```

| Option           | Description |
|------------------|-------------|
| `:action`        | The name of the [reCAPTCHA action](https://developers.google.com/recaptcha/docs/v3#actions) that we are verifying. Set to `false` or `nil` to skip verifying that the action matches.
| `:minimum_score` | Provide a threshold to meet or exceed. Threshold should be a float between 0 and 1 which will be tested as `score >= minimum_score`. (Default: `nil`) |

### Multiple actions on the same page

According to https://developers.google.com/recaptcha/docs/v3#placement,

> Note: You can execute reCAPTCHA as many times as you'd like with different actions on the same page.

You will need to verify each action individually with a separate call to `verify_recaptcha`.

```ruby
result_a = verify_recaptcha(action: 'a')
result_b = verify_recaptcha(action: 'b')
```

Because the response tokens for multiple actions may be submitted together in the same request, they
are passed as a hash under `params['g-recaptcha-response-data']` with the action as the key.

It is recommended to pass `external_script: false` on all but one of the calls to
`recaptcha` since you only need to include the script tag once for a given `site_key`.

## `recaptcha_reply`

After `verify_recaptcha` has been called, you can call `recaptcha_reply` to get the raw reply from recaptcha. This can allow you to get the exact score returned by recaptcha should you need it.

```ruby
if verify_recaptcha(action: 'login')
  redirect_to @user
else
  score = recaptcha_reply['score']
  Rails.logger.warn("User #{@user.id} was denied login because of a recaptcha score of #{score}")
  render 'new'
end
```

`recaptcha_reply` will return `nil` if the the reply was not yet fetched.

## I18n support

reCAPTCHA supports the I18n gem (it comes with English translations)
To override or add new languages, add to `config/locales/*.yml`

```yaml
# config/locales/en.yml
en:
  recaptcha:
    errors:
      verification_failed: 'reCAPTCHA was incorrect, please try again.'
      recaptcha_unreachable: 'reCAPTCHA verification server error, please try again.'
```

## Testing

By default, reCAPTCHA is skipped in "test" and "cucumber" env. To enable it during test:

```ruby
Recaptcha.configuration.skip_verify_env.delete("test")
```

## Alternative API key setup

### Recaptcha.configure

```ruby
# config/initializers/recaptcha.rb
Recaptcha.configure do |config|
  config.site_key  = '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyy'
  config.secret_key = '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxx'

  # Uncomment the following line if you are using a proxy server:
  # config.proxy = 'http://myproxy.com.au:8080'

  # Uncomment the following lines if you are using the Enterprise API:
  # config.enterprise = true
  # config.enterprise_api_key = 'AIzvFyE3TU-g4K_Kozr9F1smEzZSGBVOfLKyupA'
  # config.enterprise_project_id = 'my-project'
end
```

### Recaptcha.with_configuration

For temporary overwrites (not thread-safe).

```ruby
Recaptcha.with_configuration(site_key: '12345') do
  # Do stuff with the overwritten site_key.
end
```

### Per call

Pass in keys as options at runtime, for code base with multiple reCAPTCHA setups:

```ruby
recaptcha_tags site_key: '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyy'

# and

verify_recaptcha secret_key: '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxx'
```


## hCaptcha support

[hCaptcha](https://hcaptcha.com) is an alternative service providing reCAPTCHA API.

To use hCaptcha:
1. Set a site and a secret key as usual
2. Set two options in `verify_url` and `api_service_url` pointing to hCaptcha API endpoints.
3. Disable a response limit check by setting a `response_limit` to the large enough value (reCAPTCHA is limited by 4000 characters).
4. It is not required to change a parameter name as [official docs suggest](https://docs.hcaptcha.com/switch) because API handles standard `g-recaptcha` for compatibility.

```ruby
# config/initializers/recaptcha.rb
Recaptcha.configure do |config|
  config.site_key  = '6Lc6BAAAAAAAAChqRbQZcn_yyyyyyyyyyyyyyyyy'
  config.secret_key = '6Lc6BAAAAAAAAKN3DRm6VA_xxxxxxxxxxxxxxxxx'
  config.verify_url = 'https://hcaptcha.com/siteverify'
  config.api_server_url = 'https://hcaptcha.com/1/api.js'
  config.response_limit = 100000
end
```

hCaptcha uses a scoring system (higher number more likely to be a bot) which is inverse of the reCaptcha scoring system (lower number more likely to be a bot). As such, a `maximum_score` attribute is provided for use with hCaptcha.

```ruby
result = verify_recaptcha(maximum_score: 0.7)
```

| Option           | Description |
|------------------|-------------|
| `:maximum_score` | Provide a threshold to meet or fall below. Threshold should be a float between 0 and 1 which will be tested as `score <= maximum_score`. (Default: `nil`) |

## Misc
 - Check out the [wiki](https://github.com/ambethia/recaptcha/wiki) and leave whatever you found valuable there.
 - [Add multiple widgets to the same page](https://github.com/ambethia/recaptcha/wiki/Add-multiple-widgets-to-the-same-page)
 - [Use Recaptcha with Devise](https://github.com/plataformatec/devise/wiki/How-To:-Use-Recaptcha-with-Devise)

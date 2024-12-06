## 2.0.9
- Do not accept expired invitation on password reset ([#897](https://github.com/scambra/devise_invitable/pull/897))

## 2.0.8
- Fix for turbo stream

## 2.0.7
- Allow customizing invalid_token_path_for, the path to redirect users who try to accept with invalid token
- Don't override registrations controller in routes if module option is used
- Fix typo in spanish translation, add Catalan translation ([#857](https://github.com/scambra/devise_invitable/pull/857))
- Fix for ruby 3.2.0

## 2.0.6
- Fix submit form failure with turbolinks, fixes ([#865](https://github.com/scambra/devise_invitable/issues/865))
- Fix obsolete symbols in German translation ([#864](https://github.com/scambra/devise_invitable/pull/864))
- Allow to provide validate option to the instance method "invite!", default to follow the setting validate_on_invite

## 2.0.5
- Fix NoMethodError in random_password when validatable is not used ([#850](https://github.com/scambra/devise_invitable/pull/850))

## 2.0.4
- Fix devise deprecations ([#842](https://github.com/scambra/devise_invitable/pull/842))
- Update translations ([#844](https://github.com/scambra/devise_invitable/pull/844), [#845](https://github.com/scambra/devise_invitable/pull/845))
- Fix/enforce initial password length to follow devise ([#848](https://github.com/scambra/devise_invitable/pull/848))

## 2.0.3
- Add locales ([#834](https://github.com/scambra/devise_invitable/pull/834), [#835](https://github.com/scambra/devise_invitable/pull/835))
- Remove index on invitations_count column ([#830](https://github.com/scambra/devise_invitable/pull/830))

## 2.0.2
- Fix ruby 2.7 deprecation warning

## 2.0.1
- Use per-model allow_insecure_sign_in_after_accept ([#790](https://github.com/scambra/devise_invitable/pull/790))

## 2.0.0
- Remove deprecated devise_error_messages! from templates ([#786](https://github.com/scambra/devise_invitable/pull/785))
- Drop Devise < 4.6 support ([#786](https://github.com/scambra/devise_invitable/pull/786))
- Drop Rails 4.2 support ([#785](https://github.com/scambra/devise_invitable/pull/785))
- Drop Ruby 2.1 support

## 1.7.5
- Add add_taken_error ([#768](https://github.com/scambra/devise_invitable/pull/768))
- Add invitation_taken? ([#769](https://github.com/scambra/devise_invitable/pull/769))
- Rollback invitation_token and invitation_accepted_at if saving failed ([#758](https://github.com/scambra/devise_invitable/pull/758))
- Don't overwrite confirmed_at ([#761](https://github.com/scambra/devise_invitable/pull/761))
- Check model responds to confirmed_at= ([#756](https://github.com/scambra/devise_invitable/pull/756))
- Cleanup mailer views ([#753](https://github.com/scambra/devise_invitable/pull/753))

## 1.7.4
- Fix invitation_period_valid? with no timestamp ([#743](https://github.com/scambra/devise_invitable/pull/743))
- fix for ActionController::UnfilteredParameters error on rails 5.2 ([commit](https://github.com/scambra/devise_invitable/commit/481c6b019a41ed913514464e5d5637d7bbf0618b))

## 1.7.3
- Fix `after_{invite,accept}_path_for` ([#737](https://github.com/scambra/devise_invitable/pull/737))
- Hide invitable attributes from `#inspect` ([#736](https://github.com/scambra/devise_invitable/pull/736))
- Generate migration template with version for rails >= 5 ([commit](https://github.com/scambra/devise_invitable/commit/3c44886964a8b3f44ad39c7b0aedd93db45b5815))
- Set `@accepting_invitation` to false after accepting ([#710](https://github.com/scambra/devise_invitable/pull/710))
- Override `send_password_change_notification` to handle accepting invitation ([#718](https://github.com/scambra/devise_invitable/pull/718))

## 1.7.2
- Sign out before accepting the invitation if the user logged in

## 1.7.1
- Allow to set invited_by_* options on model
- created_by_invite scope and test method checks invitation_created_at, because invitation_sent_at can be nil if skip_invitation is used

## 1.7.0

- Drop devise < 4 support
- Fix tests for devise 4.2

## 1.6.1

- Support 2 arguments on after_invite_path_for, inviter and invitee
- Support mongoid 6.0 (use :optional on invited_by relation)
- Support devise 4.1

## 1.6.0

- Support devise 4.0 and rails 5.0
- Add before/after invitation_created callbacks
- Fix invitation_due_at when invite_for is 0
- Add plain text mailer template
- Ruby 1.9 not supported anymore
- Adds :require_password_on_accepting config option, and ensure invitation is not accepted if password is required and removed from form

## 1.5.5

- Add optional options hash to invite! methods, they will be used for send_devise_notification call

## 1.5.4

- Ensure that all invited user passwords conform to a format
- Call set_minimum_password_length (if exists) on accept invitation as devise does
- Controllers inheriting from Devise::InvitationsController will now use 'devise.invitations' translations
  when using Devise >## 3.5. See https://github.com/plataformatec/devise/pull/3407 for more details.
- Add invitation due date to mailer

## 1.5.3

- Fix #585, avoid generating new password if there already is a encrypted one
- Give error if trying to register with a registered email

## 1.5.2

- Fix #571, accept invitation when password changes only if reset_password_token was present
- Add support for setting invited_by foreign key
- Set random initial password for invited users
- Don't override password while User.invite!

## 1.5.1

- Fix #562 Avoid using after_password_reset
- Fix #564

Compare: https://github.com/scambra/devise_invitable/compare/v1.5.0...v1.5.1

## 1.5.0

Override valid_password? and unauthenticated_message instead of active_for_authentication? and inactive_message, active_for_authentication? doesn't work for default behavior of invited users without password

- Get list & check for user(s) created by invite irrespective of status
- Update simple_form template's hash syntax
- Update migration template's hash syntax
- Check if after_password_reset is defined

Compare: https://github.com/scambra/devise_invitable/compare/v1.4.2...v1.5.0

## 1.4.2

- Add option to allow controlling of auto sign in functionality for security
- Add intermediate method in active_for_authentication? for more flexibility
- Add intermediate block_from_invitation? method for more flexibility
- Fix undefined method `invite_key_fields'
- Fix override valid_password? instead of active_for_authentication? (fixes #541)

Compare: https://github.com/scambra/devise_invitable/compare/v1.4.1...v1.4.2

## 1.4.1

- Begin testing against devise 3.4
- Use current_inviter to get redirect path after invite
  (https://github.com/scambra/devise_invitable/pull/523)

Compare: https://github.com/scambra/devise_invitable/compare/v1.4.0...v1.4.1

## 1.4.0

Override active_for_authentication? and inactive_message instead of valid_password?
To use counter_cache, invited_by_counter_cache must be set, no more checking of invitations_count to enable counter cache

Compare: https://github.com/scambra/devise_invitable/compare/v1.3.6...v1.4.0

## 1.3.6

- Regenerate invitation token each time even if "skip_invitation" was true
- Add passing a block to instance #invite! method
- Improvements to tests

Compare: https://github.com/scambra/devise_invitable/compare/v1.3.5...v1.3.6

## 1.3.5

No notes yet, contributions welcome.

## 1.3.0

Now devise 3.1 compatible, @token must be used instead of @resource.invitation_token in mail views

## 1.2.0

Add invitation_created_at column which is set when invitation is created even when sending is skipped. This new field is used to check invitation period valid

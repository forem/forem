# Bullet Overview for Developers

This file aims to give developers a quick tour of the bullet internals, making
it (hopefully) easier to extend or enhance the Bullet gem.

## General Control Flow aka. 10000 Meter View

When Rails is initialized, Bullet will extend ActiveRecord (and if you're using
Rails 2.x ActiveController too) with the relevant modules and methods found
in lib/bullet/active_recordX.rb and lib/bullet/action_controller2.rb. If you're
running Rails 3, Bullet will integrate itself as a middleware into the Rack
stack, so ActionController does not need to be extended.

The ActiveRecord extensions will call methods in a given detector class, when
certain methods are called.

Detector classes contain all the logic to recognize
a noteworthy event. If such an event is detected, an instance of the
corresponding Notification class is created and stored in a Set instance in the
main Bullet module (the 'notification collector').

Notification instances contain the message that will be displayed, and will
use a Presenter class to display their message to the user.

So the flow of a request goes like this:

1. Bullet.start_request is called, which resets all the detectors and empties
   the notification collector
2. The request is handled by Rails, and the installed ActiveRecord extensions
   trigger Detector callbacks
3. Detectors once called, will determine whether something noteworthy happened.
   If yes, then a Notification is created and stored in the notification collector.
4. Rails finishes handling the request
5. For each notification in the collector, Bullet will iterate over each
   Presenter and will try to generate an inline message that will be appended to
   the generated response body.
6. The response is returned to the client.
7. Bullet will try to generate an out-of-channel message for each notification.
8. Bullet calls end_request for each detector.
9. Goto 1.

## Adding Notification Types

If you want to add more kinds of things that Bullet can detect, a little more
work is needed than if you were just adding a Presenter, but the concepts are
similar.

* Add the class to the DETECTORS constant in the main Bullet module
* Add (if needed) Rails monkey patches to Bullet.enable
* Add an autoload directive to lib/bullet/detector.rb
* Create a corresponding notification class in the Bullet::Notification namespace
* Add an autoload directive to lib/bullet/notification.rb

As a rule of thumb, you can assume that each Detector will have its own
Notification class. If you follow the principle of Separation of Concerns I
can't really think of an example where one would deviate from this rule.

Since the detection of pathological associations is a bit hairy, I'd recommend
having a look at the counter cache detector and associated notification to get
a feel for what is needed to get off the ground.

### Detectors

The only things you'll need to consider when building your Detector class is
that it will need to supply the .start_request, .end_request and .clear class
methods.

Simple implementations are provided by Bullet::Detector::Base for start_request
and end_request, you will have to supply your own clear method.

### Notifications

For notifications you will want to supply a #title and #body instance method,
and check to see if the #initialize and #full_notice methods in the
Bullet::Notification::Base class fit your needs.

---
title: Internal User Interface
---

# User Interface

Our internal dashboard is primarily ERB views that render on the server.
Largely, we try to adhere to
[ActionView](https://guides.rubyonrails.org/action_view_overview.html)'s
conventions in these views.

For layout, basic styles, and some interactions, we use
[Bootstrap 4](https://getbootstrap.com/). DEV isn't dedicated to using Bootstrap
for everything, but because our design team hasn't spent much time on these
views, we find it's easier to stick with something many developers already know.

When a view requires some custom interactivity, we've historically leaned on
vanilla JavaScript or jQuery, but going forward we've elected to use
[StimulusJS](https://stimulusjs.org/) for DOM manipulation and interactivity
inside of internal.

# Forms

Inside of the internal views, we're
[actively moving from the old ERB syntax for forms](https://m.patrikonrails.com/rails-5-1s-form-with-vs-old-form-helpers-3a5f72a8c78a).
We tend to prefer the `form_with` helper over the previous `form_for` and
`form_tag` helpers.

# StimulusJS

Stimulus is a modest frontend framework; its primary purpose is manipulating
HTML. It does not provide templating features.

In the DEV application, [Webpacker](/frontend/webpacker/) is used to load
Stimulus controllers. Ideally, controllers serve as an abstraction for shared
functionality between views.

New controllers can be added in `/app/javascript/internal/controllers`. Unit
tests should exist for each controller in the adjacent
`/app/javascript/internal/__tests__/contollers` directory.

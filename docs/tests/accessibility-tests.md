---
title: Accessibility Tests
---

# Accessibility Tests

Accessibility testing is a form of automated and manual testing that helps us
identify some of the potential accessibility concerns on Forem.

Many a11y issues are not obvious to everyone who contributes to the Forem
project, therefore leaning on tools to help us identify these issues is a good
practice.

It's a good idea to use browser plugins while you're developing to keep an eye
out for these issues, as well as including automated tests to catch regressions
in future changes.

The [aXe devtools](https://www.deque.com/axe) extension is a great place to get
started. It works in both Firefox and Chrome. Use an extension like this one to
find potential a11y issues in your workflow.

## Automated testing in Preact

An overarching a11y testing strategy isn't currently in place for the Forem
application, but there are some automated tools you can take advantage of in
this project.

It is important to note that automated accessibility testing is only effective
at finding ~30% of accessibility issues. It's important to do manual a11y
testing as well.

When you're writing Preact components, you can include some basic a11y testing
in your unit tests with [jest-axe](https://github.com/nickcolley/jest-axe).

If you're still curious
[there are some great talks on accessibility for developers](https://www.youtube.com/watch?v=8E9AEZjglqI).

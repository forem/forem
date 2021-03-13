---
title: Accessibility Tests
---

# Accessibility Tests

Accessibility testing is a form of automated and manual testing that helps us
identify some of the potential accessibility concerns on Forem. See also, the
[Forem Frontend Accessibility docs](https://docs.forem.com/frontend/accessibility/).

Many accessibility (a11y) issues are not obvious to everyone who contributes to
the Forem project, therefore leaning on tools to help us identify these issues
is a good practice.

It's a good idea to use browser plugins while you're developing to keep an eye
out for these issues, as well as including automated tests to catch regressions
in future changes.

The [axe devtools](https://www.deque.com/axe) extension is a great place to get
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

## PR Review Checklist

Pull Requests should include accessibility testing to prevent barriers from
making it into the codebase. Sometimes issues found may be out of scope for a
particular PR – those can be opened as separate issues to be followed up on.

Test the functionality in Forem-supported browsers for accessibility impact:
Chrome and Firefox were popular for Windows screen reader users in 2019
[according to WebAIM](https://webaim.org/projects/screenreadersurvey8/#browsers).
Safari is the most common choice for Voiceover users on the Mac, even if Chrome
is widely used for development. Mobile browsers are worth checking, too.

1. Keyboard: navigate the page without using a mouse or trackpad.
   - Can you reach and operate the interactive controls like menus, buttons, and
     other widgets?
   - Can you see your focus point on the screen, and does the focus style have
     adequate contrast?
   - Does your focus point get lost or hidden behind any layers with items
     needing to be disabled/hidden?
1. Run a browser extension.
   - Use [axe](https://deque.com/axe),
     [Accessibility Insights](https://accessibilityinsights.io), Chrome's
     Lighthouse Audit, or
     [WAVE](https://chrome.google.com/webstore/detail/wave-evaluation-tool/jbbplnpkjmmeebjpijfedlgcdilocofh)
     to run accessibility tests in the DevTools.
   - Prioritize relevant, higher-impact violations and issues first.
1. Test color contrast.
   - Pay extra attention to color contrast findings in your browser extension
     tests, since it's the most common accessibility issue on the internet.
   - The
     [Chrome color picker with contrast ratio line](https://developers.google.com/web/tools/chrome-devtools/accessibility/reference#contrast)
     and
     [WebAIM contrast checker](https://webaim.org/resources/contrastchecker/)
     are helpful tools for tweaking colors to meet
     [WCAG requirements](https://webaim.org/articles/contrast/).

### Additional accessibility tests for PR reviews

1. Screen reader testing
   - Get feedback from people who use screen readers regularly if at all
     possible.
   - Understand that if you're a new screen reader user, there might be a
     learning curve that can impact your results.
   - Navigate through a UI change using a screen reader such as Mac
     [Voiceover with Safari](https://webaim.org/articles/voiceover/), and
     [NVDA](https://webaim.org/articles/nvda/) with Firefox or Chrome on
     Windows.
1. Zoom and magnification
   - In the web browser, try zooming in from 200% to 500%.
   - Would the layout or change of functionality be impacted by someone needing
     to magnify their screen? Are there alternative styling or other solutions
     that would make zooming any easier?

---
title: Accessibility
---

# Accessibility

To make Forem the most inclusive community platform around, accessibility should
be considered to enable people with disabilities to create and consume content.

## The Basics

Forem UI changes should consider accessibility wherever possible. Common issues
to watch out for in frontend code:

- [Adequate color contrast](https://webaim.org/articles/contrast/evaluating)
- [Semantic structure and headings](https://webaim.org/techniques/semanticstructure/)
- [Alternative text for images](https://webaim.org/techniques/alttext/)
- [Unique button and link text](https://webaim.org/techniques/hypertext/link_text)
- [Accessible forms with labels](https://webaim.org/techniques/forms/)
- [Visible keyboard focus styles](https://www.washington.edu/accessibility/checklist/focus/)

## More Advanced Things

If you're working on something JavaScript-heavy or animated, there are a few
additional considerations for accessibility:

- [Forem Accessibility Tests](https://docs.forem.com/tests/accessibility-tests/)
- [Intro to ARIA](https://webaim.org/techniques/aria/)
- [Handle focus for client-side interactions](https://dev.to/robdodson/managing-focus-64l)
- [Reducing motion with CSS media queries](https://css-tricks.com/introduction-reduced-motion-media-query/)
- [Linting with eslint-plugin-jsx-a11y](https://github.com/jsx-eslint/eslint-plugin-jsx-a11y)
- [Testing with Jest-axe](https://dev.to/bdougieyo/accessibility-testing-in-react-with-jest-axe-l7k)

## Accessibility Testing

See a list of testing steps to follow during development or for a Pull Request
review on the
[Forem Accessibility Testing Docs](https://docs.forem.com/tests/accessibility-tests/).

## Resources

There's a wealth of information out there to learn about digital accessibility!
Here are some resources:

- [W3C's Web Accessibility Initiative](https://www.w3.org/WAI/)
- [Web Content Accessibility Guidelines](https://www.w3.org/TR/WCAG21/)
- [ARIA Authoring Practices](https://www.w3.org/TR/wai-aria-practices-1.1/)
- [WebAIM](http://webaim.org/)
- [A11y Project](https://a11yproject.com)
- [Deque University](https://dequeuniversity.com/)
- [React Accessibility Docs](https://reactjs.org/docs/accessibility.html) (most
  will apply to Preact)
- [The Importance of Manual Accessibility Testing](https://www.smashingmagazine.com/2018/09/importance-manual-accessibility-testing/)
- [Accessibility Insights extension](https://accessibilityinsights.com)

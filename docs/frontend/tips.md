---
title: Tips
---

# Tips

## About query selectors

JavaScript has many different query selectors, some seemingly interchangeable,
for example:

- `document.head` and `document.body`
- `document.getElementById`, `document.getElementsByClassName` and
  `document.getElementsByTagName`
- `document.querySelector` and `document.querySelectorAll`

Knowing which to use for optimal performance depends on the situation, but a
good rule of thumb is:

- to access the **head** of the document, use `document.head` over
  `document.getElementsByTagName('head')`
- to access the **body** of the document, use `document.body` over
  `document.getElementsByTagName('body')`
- to access an element by id use `document.getElementById('id')` over
  `document.querySelector('#id')`
- to access one element by class name use
  `document.getElementsByClassName('className')[0]` over
  `document.querySelector('.className')`
- to access multiple elements by class name use
  `document.getElementsByClassName('className')` over
  `document.querySelectorAll('.className')`
- to access one element by tag name use
  `document.getElementsByTagName('tagName')[0]` over
  `document.querySelector('tagName')`
- to access multiple elements by tag name use
  `document.getElementsByTagName('tagName')` over
  `document.querySelectorAll('tagName')`

In most cases `querySelector` and `querySelectorAll` should be used only on
selectors more sophisticated than a simple id, class or tag name.

### Resources

- [Forem PR 6380](https://github.com/forem/forem/issues/6380#issuecomment-592989438)
- [Why is getElementsByTagName() faster than querySelectorAll()?](https://humanwhocodes.com/blog/2010/09/28/why-is-getelementsbytagname-faster-that-queryselectorall/)
- [What is the difference between querySelectorAll and getElementsByTagName?](https://stackoverflow.com/a/30921553/4186181)

## Service workers in development

By default our
[service worker code](https://github.com/forem/forem/blob/master/app/views/service_worker/index.js.erb)
doesn't run in development.

If you're planning to do any work around service workers you'll need to enable
them by setting the `SKIP_SERVICEWORKERS` environment variable to `"false"`.

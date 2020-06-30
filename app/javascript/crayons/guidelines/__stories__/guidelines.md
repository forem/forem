# Crayons

Crayons is the design system of Forem. It will provide you everything you need
to quickly design, build, and ship coherent experience and style across Forem.

In other words - Crayons defines our design language and frontend approach.

Crayons is a combination of:

- **Components** to create features or views. Think of buttons, form elements,
  tabs, etc.

- **Utility-first CSS classes** enabling developers to create frontend code
  almost without touching CSS.
  [Click here to read more about Utility-first CSS](https://www.notion.so/devto/Utility-First-CSS-19a8c3a74b3d4d23a802923be206aba9)
  .

## How to best use Crayons?

Imagine you have to build a new feature or a view. A designer will likely give
you a mockup and there are several scenarios that can happen:

- **Mockup uses existing components.** In that case you should be able to simply
  copy and paste code responsible for rendering specific component and call it a
  day.

- **Mockup uses existing components but they look customized a little.** You
  have two options:

  - Copy and paste component code and customize it with _utility-first classes_
    . It makes sense if you need to make small changes like increase padding,
    make border thicker etc...

  - Consider extending existing component to support your case. This is more
    time-consuming solution because you should make sure it's context-agnostic -
    so it should work in any context, not only for your feature.

- **Mockup doesn't use existing components.** Looks like you will have to build
  everything from scratch. And you have two options again:

  - You may either build it using _utility-first classes_ , so you don't have to
    be worried where to put CSS or how to structure it. _Utility-first classes_
    should let you not only apply simple customizations like padding etc. but
    they should let you also create entire views.

  - You can split your work - try to build some things with _utility-first
    classes_ (so you can move on faster), but also consider building actual
    reusable components.

- **It's something completely new.** You probably think you'll have to write
  tons of custom CSS and import your .scss file somewhere. Well, hopefully not.
  As mentioned earlier, _utility-first classes_ let you create even complex
  components without a single line of CSS. From a design point of view, this is
  the preferred way to write frontend code instead of creating new SCSS files.
  Every line of CSS you write, the more CSS we have to maintain, the more our
  users have to download, and the more bytes we have to host.

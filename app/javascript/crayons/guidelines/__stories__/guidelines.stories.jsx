import { h } from 'preact';

import '../../storybook-utilities/designSystem.scss';

export default {
  title: '1_Guidelines',
};

export const Crayons = () => (
  <div className="container">
    <h1>Crayons</h1>
    <p>
      Crayons is the design system of DEV. It will provide you everything you
      need to quickly design, build, and ship coherent experience and style
      across DEV.
    </p>
    <p>
      In other words - Crayons defines our design language and frontend
      approach.
    </p>
    <p>Crayons is a combination of:</p>
    <ul>
      <li>
        <strong>Components</strong>
        {' '}
        to create features or views. Think of
        buttons, form elements, tabs, etc.
      </li>
    </ul>
    <ul>
      <li>
        <strong>Utility-first CSS classes</strong>
        {' '}
        enabling developers to create
        frontend code almost without touching CSS.
        {' '}
        <a href="https://www.notion.so/devto/Utility-First-CSS-19a8c3a74b3d4d23a802923be206aba9">
          Click here to read more about Utility-first CSS
        </a>
        .
      </li>
    </ul>
    <p />
    <h2>How to best use Crayons?</h2>
    <p>
      Imagine you have to build a new feature or a view. A designer will likely
      give you a mockup and there are several scenarios that can happen:
    </p>
    <ul>
      <li>
        <strong>Mockup uses existing components.</strong>
        {' '}
        In that case you
        should be able to simply copy and paste code responsible for rendering
        specific component and call it a day.
      </li>
    </ul>
    <ul>
      <li>
        <strong>
          Mockup uses existing components but they look customized a little.
        </strong>
        {' '}
        You have two options:
        <ul>
          <li>
            Copy and paste component code and customize it with
            {' '}
            <em>utility-first classes</em>
            . It makes sense if you need to make
            small changes like increase padding, make border thicker etc...
          </li>
        </ul>
        <ul>
          <li>
            Consider extending existing component to support your case. This is
            more time-consuming solution because you should make sure it&#x27;s
            context-agnostic - so it should work in any context, not only for
            your feature.
            {' '}
          </li>
        </ul>
      </li>
    </ul>
    <ul>
      <li>
        <strong>Mockup doesn&#x27;t use existing components.</strong>
        {' '}
        Looks like
        you will have to build everything from scratch. And you have two options
        again:
        <ul>
          <li>
            You may either build it using 
            {' '}
            <em>utility-first classes</em>
            , so you
            don&#x27;t have to be worried where to put CSS or how to structure
            it. 
            {' '}
            <em>Utility-first classes</em>
            {' '}
            should let you not only apply
            simple customizations like padding etc. but they should let you also
            create entire views.
          </li>
        </ul>
        <ul>
          <li>
            You can split your work - try to build some things with
            {' '}
            <em>utility-first classes</em>
            {' '}
            (so you can move on faster), but also
            consider building actual reusable components.
          </li>
        </ul>
      </li>
    </ul>
    <ul>
      <li>
        <strong>It&#x27;s something completely new.</strong>
        {' '}
        You probably think
        you&#x27;ll have to write tons of custom CSS and import your .scss file
        somewhere. Well, hopefully not. As mentioned earlier,
        {' '}
        <em>utility-first classes</em>
        {' '}
        let you create even complex components
        without a single line of CSS. From a design point of view, this is the
        preferred way to write frontend code instead of creating new SCSS files.
        Every line of CSS you write, the more CSS we have to maintain, the more
        our users have to download, and the more bytes we have to host.
      </li>
    </ul>
  </div>
);

Crayons.story = {
  name: '1.1_Crayons',
};

export const Components = () => (
  <div className="container">
    <h1>Components</h1>
    <p>
      DEV is a Rails application. Most of what we build for views uses ERB
      templates (*.html.erb files). We also build out parts of or sometimes
      complete views using
      {' '}
      <a href="https://docs.dev.to/frontend/preact/">Preact</a>
      , typically for
      the logged on user experience. For example, the main page feed.
    </p>
    <p>
      Because of that, we components that are written in pure HTML &amp; CSS as
      well as Preact.
    </p>
    <h3>BEM class naming</h3>
    <p>
      The entire design system uses the
      {' '}
      <a href="http://getbem.com/naming/">BEM</a>
      {' '}
      methodology for naming CSS
      classes. Even Preact components under the hood use it.
    </p>
    <h3>crayons-*</h3>
    <p>
      Crayons is the name of our design system. All Crayons components use the
      {' '}
      <code>crayons-</code>
      {' '}
      prefix. It&#x27;s useful because we can easily
      identify what
      <strong>IS</strong>
      {' '}
      and what
      <strong>IS NOT</strong>
      {' '}
      a
      Crayons component. It&#x27;s also practical because Crayons was
      implemented when we already had tons of other frontend classes in the
      codebase. It prevents overwriting styles by other CSS and it&#x27;s very
      unlikely someone has ever created a
      <code>.crayons-btn</code>
      {' '}
      style BUT
      it&#x27;s very likely someone has created
      <code>.btn</code>
      {' '}
      style...
    </p>
    <h2>HTML &amp; CSS Components</h2>
    <p>
      You&#x27;ll need to copy piece of html code responsible for rendering a
      component and that&#x27;s it. Imagine a simple button component. The code
      below will render a 
      {' '}
      <strong>primary button</strong>
      {' '}
      with specific styling:
    </p>
    <pre>
      <code>
        &lt;button class=&quot;crayons-btn&quot;&gt;Hello&lt;/button&gt;
      </code>
    </pre>
    <p>
      Crayons offers different variants for a button. A button can be one of the
      following variants: primary, secondary, outlined, danger, ghost, with
      icon, and so on. All of the components and its variations are described in
      the Components section.
    </p>
    <p>
      Imagine you need a small (size 
      {' '}
      <strong>s</strong>
      ), 
      {' '}
      <strong>secondary</strong>
      {' '}
      type. In this case you will need to apply
      specific modifier class for that:
    </p>
    <pre>
      <code>
        &lt;button class=&quot;crayons-btn crayons-btn--secondary
        crayons-btn--s&quot;&gt;Hello&lt;/button&gt;
      </code>
    </pre>
    <h2>Preact Components</h2>
    <p>
      The same button above that was created with pure HTML using modifying
      classes is also a Preact component.
    </p>
    <pre>
      <code>
        import &#123; Button &#125; from &#x27;@crayons&#x27;; //... &lt;Button
        size=&quot;s&quot; variant=&quot;secondary&quot;&gt;Hello&lt;Button&gt;
      </code>
    </pre>
    <p>
      To import a design system component, e.g. 
      {' '}
      <code>&lt;Button /&gt;</code>
      ,
      import it from 
      {' '}
      <code>@crayons</code>
      . Instead of modifying CSS classes,
      modify props, e.g. 
      {' '}
      <code>variant=&quot;primary&quot;</code>
      .
    </p>
  </div>
);

Components.story = {
  name: '1.2_Components',
};

export const Styling = () => (
  <div className="container">
    <h1>Styling</h1>
    <p>
      If you ever end up writing your own CSS, it&#x27;s worth to know several
      things.
    </p>
    <h2>Mobile first approach</h2>
    <p>
      We try to write frontend code for mobile and then use media queries for
      bigger breakpoints. You can read more about it in Responsiveness section.
    </p>
    <h2>SCSS</h2>
    <p>
      We use SCSS as a CSS preprocessor. So you can use all the magic that SCSS
      offers.
    </p>
    <h2>CSS Variables</h2>
    <p>
      Even though we use SCSS, we prefer to use native CSS variables because
      they are more flexible. You should be able to view all variables we have
      in 
      {' '}
      <code>app/assets/stylesheets/config/_variables.scss</code>
      {' '}
      file. Since
      this file is imported everywhere, you should not need to import that by
      your own.
    </p>
    <p>
      Fun fact: there&#x27;s one exception to that: responsiveness breakpoints.
      Since you can&#x27;t use a CSS variables when defining a media query, this
      is the only case when we use SCSS variables. It&#x27;s just easier.
    </p>
    <h2>Themes</h2>
    <p>
      DEV support multiple themes so you should always test your work against
      all themes. We have a file with all color variables and each theme has its
      own too.
    </p>
    <ul>
      <li>
        Default theme: 
        {' '}
        <code>app/assets/stylesheets/config/_colors.scss</code>
      </li>
    </ul>
    <ul>
      <li>
        Other themes (minimal, night, pink, hacker):
        {' '}
        <code>app/assets/stylesheets/themes</code>
      </li>
    </ul>
    <h2>Import.scss</h2>
    <p>
      When you create a new SCSS file you may want to import one file at the top
      of your new file: 
      {' '}
      <code>app/assets/stylesheets/config/_import.scss</code>
      {' '}
      - it contains some helpers as well as breakpoint variables I mentioned
      earlier.
    </p>
    <h2>Folders</h2>
    <p>
      You can access all of the SCSS files in
      {' '}
      <code>app/assets/stylesheets</code>
      {' '}
      folder.
    </p>
    <ul>
      <li>
        <code>/base</code>
        {' '}
        - this folder contains some fundamental styling for
        layouts, resets and icons.
      </li>
    </ul>
    <ul>
      <li>
        <code>/components</code>
        {' '}
        - this folder contains separate SCSS file for
        each component we have... tags, buttons, forms, ...
      </li>
    </ul>
    <ul>
      <li>
        <code>/config</code>
        {' '}
        - this folder contains bunch of configuration
        files. These are worth explaining:
        <ul>
          <li>
            <code>_colors.scss</code>
            {' '}
            - I mentioned it couple lines above - it
            contains all color variables used in Crayons.
          </li>
        </ul>
        <ul>
          <li>
            <code>_generator.scss</code>
            {' '}
            - it&#x27;s basically a huge SCSS mixin
            generating ALL our utility classes.
          </li>
        </ul>
        <ul>
          <li>
            <code>_import.scss</code>
            {' '}
            - it contains bunch of helpers for SCSS as
            well as media breakpoints variables.
          </li>
        </ul>
        <ul>
          <li>
            <code>_variables.scss</code>
            {' '}
            - it contains all CSS native variables.
          </li>
        </ul>
      </li>
    </ul>
    <ul>
      <li>
        <code>/themes</code>
        {' '}
        - this folder contains color declarations for other
        themes.
      </li>
    </ul>
    <ul>
      <li>
        Other folders and top level files are mostly legacy... :) We still use
        them, but slowly trying to move all the styling to appropriate
        Crayons-related files. Exceptions:
        <ul>
          <li>
            <code>crayons.scss</code>
            {' '}
            - this is one importing everything
            Crayons-related like variables, components styling, utility classes
            etc.
          </li>
        </ul>
        <ul>
          <li>
            <code>minimal.scss</code>
            {' '}
            - this one is actually one of the main
            stylesheets from pre-Crayons era. It imports everything basically
            :).
          </li>
        </ul>
      </li>
    </ul>
  </div>
);

Styling.story = {
  name: '1.3_Styling',
};

import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import { number } from '@storybook/addon-knobs';
import { Snackbar } from '../Snackbar';

export default {
  title: 'App Components/Snackbar',
};

export const Description = () => (
  <div className="container">
    <div className="body">
      <h2>Snackbars</h2>
      <p>
        Snackbars inform users of a process that an app has performed. They
        appear temporarily, towards the bottom of the screen. They shouldn’t
        interrupt the user experience, and they don’t require user input to
        disappear.
      </p>
      <p>
        A Snackbar can contain a single action. Because they disappear
        automatically, the action shouldn’t be “Dismiss” or “Cancel.”
      </p>
      <p>
        A Snackbar disappears after 5000ms by default. Countdown will be paused
        when user mouse over the snackbar.
      </p>
    </div>
    <div>
      <h3>Usage</h3>
      <p>
        The Snackbar component has a default lifespan of 5000ms, if `no
        lifespan` prop is provided.
      </p>
      <h4>No Actions</h4>
      <pre>
        &lt;Snackbar lifespan=&quot;&apos;4000&quot;&apos;&gt;Hello
        World!&lt;/Snackbar&gt;
      </pre>
      <Snackbar lifespan="4000">Hello World!</Snackbar>
      <h4>With One or More Actions</h4>
      <pre>
        const actions = &#91; &#123; text: &apos;Action 1&apos;, handler: event
        =&gt; &#123; console.log&#40;&apos;Action 1 clicked&apos;&#41; &#125;
        &#125;, &#123; text: &apos;Action 2&apos;, handler: event =&gt; &#123;
        console.log&#40;&apos;Action 2 clicked&apos;&#41; &#125; &#125;&#93;
        &#13; &#13; &#13; &lt;Snackbar lifespan=&quot;&apos;3000&quot;&apos;
        actions= &#123;actions&#125; &gt;Hello World!&lt;/Snackbar&gt;
      </pre>
      <Snackbar lifespan="4000">Hello World!</Snackbar>
    </div>
  </div>
);

Description.story = {
  name: 'description',
};

export const Default = () => (
  <Snackbar lifespan={number('lifespan', 5000)}>Hello world!</Snackbar>
);

Default.story = {
  name: 'default',
};

export const WithOneAction = () => {
  const actions = [
    {
      text: 'Action 1',
      handler: action('Action 1 fired.'),
    },
  ];
  return (
    <Snackbar actions={actions} lifespan={number('lifespan', 5000)}>
      Hello world!
    </Snackbar>
  );
};

WithOneAction.story = {
  name: 'with one action',
};

export const WithMultipleActions = () => {
  const actions = [
    {
      text: 'Action 1',
      handler: action('Action 1 fired.'),
    },
    {
      text: 'Action 2',
      handler: action('Action 2 fired.'),
    },
    {
      text: 'Action 3',
      handler: action('Action 3 fired.'),
    },
  ];
  return (
    <Snackbar actions={actions} lifespan={number('lifespan', 5000)}>
      Hello world!
    </Snackbar>
  );
};

WithMultipleActions.story = {
  name: 'with multiple actions',
};

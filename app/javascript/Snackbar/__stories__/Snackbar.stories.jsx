import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import { number } from '@storybook/addon-knobs';
import { Snackbar, addSnackbarItem } from '../Snackbar';

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
      <h4>With One or More Actions</h4>
      <pre>
        const actions = &#91; &#123; text: &apos;Action 1&apos;, handler: event
        =&gt; &#123; console.log&#40;&apos;Action 1 clicked&apos;&#41; &#125;
        &#125;, &#123; text: &apos;Action 2&apos;, handler: event =&gt; &#123;
        console.log&#40;&apos;Action 2 clicked&apos;&#41; &#125; &#125;&#93;
        <br />
        <br />
        <br />
        &lt;Snackbar lifespan=&quot;&apos;3000&quot;&apos; actions=
        &#123;actions&#125; &gt;Hello World!&lt;/Snackbar&gt;
      </pre>
    </div>
  </div>
);

Description.story = {
  name: 'description',
};

export const OneSnackbarItem = () => {
  addSnackbarItem({
    text: 'File uploaded successfully',
    lifespan: 3000,
  });

  return <Snackbar pollingTime={number('pollingTime', 300)} />;
};

OneSnackbarItem.story = {
  name: 'one snackbar item',
};

export const MultipleSnackbarItems = () => {
  addSnackbarItem({
    text: 'File uploaded successfully',
    lifespan: 3000,
  });

  addSnackbarItem({
    text: 'Unable to save file',
    actions: [
      { text: 'Retry', handler: action('save file retry') },
      { text: 'Abort', handler: action('abort file save') },
    ],
    lifespan: 2000,
  });

  addSnackbarItem({
    text: 'There was a network error',
    actions: [{ text: 'Retry', handler: action('retry network') }],
    lifespan: 4000,
  });

  return <Snackbar pollingTime={number('pollingTime', 300)} />;
};

MultipleSnackbarItems.story = {
  name: 'multiple snackbar items',
};

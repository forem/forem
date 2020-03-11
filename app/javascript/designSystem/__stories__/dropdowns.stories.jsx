import { h } from 'preact';
import { storiesOf } from '@storybook/react';

import './typography.scss';

storiesOf('Base/Components/HTML/Dropdowns', module)
  .add('Description', () => (
    <div className="container">
      <h2>Dropdowns</h2>
      <p>
        Dropdowns should have position relative to it’s trigger. They can be
        used for some 2nd level navigations, contextual configurations, etc...
      </p>
      <p>Dropdowns should not be bigger than 320px.</p>
      <p>Dropdown default padding should be dependent on width:</p>
      <ul>
        <li>&lt;250px: 16px</li>
        <li>251 - 320px: 24px</li>
      </ul>
      <p>
        If you need to utilize entire dropdown area and you have to get rid of
        default padding, please use modifier class
        <code>crayons-dropdown--padding-0</code>
        .
      </p>
      <p>
        FYI: Dropdowns use “Box” component as background, with Level 3
        elevation.
      </p>
    </div>
  ))
  .add('Default', () => (
    <div className="crayons-dropdown">
      Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet, consectetur
      adipisicing elit. Sequi ea voluptates quaerat eos consequuntur temporibus.
    </div>
  ))
  .add('Large', () => (
    <div className="crayons-dropdown crayons-dropdown--l">
      Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet, consectetur
      adipisicing elit. Sequi ea voluptates quaerat eos consequuntur temporibus.
    </div>
  ))
  .add('No Padding', () => (
    <div className="crayons-dropdown crayons-dropdown--padding-0">
      Hey, I&apos;m a dropdown content! Lorem ipsum dolor sit amet, consectetur
      adipisicing elit. Sequi ea voluptates quaerat eos consequuntur temporibus.
    </div>
  ));

import { h } from 'preact';
import { storiesOf } from '@storybook/react';

import './typography.scss';

storiesOf('Base/Components/HTML/Notices', module)
  .add('Description', () => (
    <div className="container">
      <h2>Notices</h2>
      <p>
        Use Notices to focus user on specific piece of content, for example (but
        not limited to):
      </p>
      <ul>
        <li>alerts after form submission, </li>
        <li>box with tip like “Did you know..?”</li>
        <li>etc...</li>
      </ul>
      <p>
        This should be simple message. And this is exactly what this Figma
        component let you do.
      </p>
      <p>By default, this component has 16px padding.</p>
    </div>
  ))
  .add('Default', () => (
    <div className="crayons-notice">This is Default Notice content.</div>
  ))
  .add('Danger', () => (
    <div className="crayons-notice crayons-notice--danger">
      This is Default Notice content.
    </div>
  ))
  .add('Warning', () => (
    <div className="crayons-notice crayons-notice--warning">
      This is Warning Notice content.
    </div>
  ))
  .add('Success', () => (
    <div className="crayons-notice crayons-notice--success">
      This is Success Notice content.
    </div>
  ))
  .add('Info', () => (
    <div className="crayons-notice crayons-notice--info">
      This is Info Notice content.
    </div>
  ));

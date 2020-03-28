import { h } from 'preact';

import './designSystem.scss';

export default {
  title: 'Components/HTML/Notices',
};

export const Description = () => (
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
);

Description.story = {
  name: 'description',
};

export const Default = () => (
  <div className="crayons-notice">This is Default Notice content.</div>
);

Default.story = {
  name: 'default',
};

export const Danger = () => (
  <div className="crayons-notice crayons-notice--danger">
    This is Default Notice content.
  </div>
);

Danger.story = {
  name: 'danger',
};

export const Warning = () => (
  <div className="crayons-notice crayons-notice--warning">
    This is Warning Notice content.
  </div>
);

Warning.story = {
  name: 'story',
};

export const Success = () => (
  <div className="crayons-notice crayons-notice--success">
    This is Success Notice content.
  </div>
);

Success.story = {
  name: 'success',
};

export const Info = () => (
  <div className="crayons-notice crayons-notice--info">
    This is Info Notice content.
  </div>
);

Info.story = {
  name: 'info',
};

import { h } from 'preact';

import '../../storybook-utiltiies/designSystem.scss';

export default {
  title: 'Components/Notices',
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

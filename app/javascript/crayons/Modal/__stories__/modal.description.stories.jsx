import { h } from 'preact';

import '../../storybook-utilities/designSystem.scss';

export default {
  title: '3_Components/Modals',
};

export const Description = () => (
  <div className="container">
    <h2>Modals</h2>
    <p>
      Modals should be positioned centered in relation to entire viewport. So
      relation to its trigger doesn’t really matter.
    </p>
    <p>Use your best judgements when choosing the right size.</p>
  </div>
);

Description.story = {
  name: 'description',
};

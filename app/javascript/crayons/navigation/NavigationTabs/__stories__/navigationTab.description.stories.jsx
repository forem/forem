import { h } from 'preact';

import '../../../storybook-utiltiies/designSystem.scss';

export default { title: 'Components/Navigation/Tabs' };

export const Description = () => (
  <div className="container">
    <h2>Navigation: Tabs</h2>
    <p>Use tabs as 2nd level navigation or filtering options.</p>
  </div>
);

Description.story = { name: 'description' };

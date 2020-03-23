import { h } from 'preact';

import './designSystem.scss';

export default { title: 'Components/HTML/Navigation/Tabs' };

export const Description = () => (
  <div className="container">
    <h2>Navigation: Tabs</h2>
    <p>Use tabs as 2nd level navigation or filtering options.</p>
  </div>
);

Description.story = { name: 'description' };

export const Default = () => (
  <div className="crayons-tabs">
    <a href="/" className="crayons-tabs__item crayons-tabs__item--current">
      Feed
    </a>
    <a href="/" className="crayons-tabs__item">
      Popular
    </a>
    <a href="/" className="crayons-tabs__item">
      Latest
    </a>
  </div>
);

Default.story = {
  name: 'default',
};

import { h } from 'preact';

import './designSystem.scss';

export default {
  title: 'Components/HTML/Navigation/Main Navigation',
};

export const Description = () => (
  <div className="container">
    <h2>Navigation: Main nav</h2>
    <p>Used as main nav in left sidebar or dropdowns...</p>
    <p>Can contain icons.</p>
  </div>
);

Description.story = { name: 'description' };

export const Default = () => (
  <div className="p-6 bg-smoke-10">
    <a href="/" className="crayons-nav-block crayons-nav-block--current">
      <span className="crayons-icon" role="img" aria-label="home">
        🏡
      </span>
      Home
    </a>
    <a href="/" className="crayons-nav-block">
      <span className="crayons-icon" role="img" aria-label="Podcasts">
        📻
      </span>
      Podcasts
    </a>
    <a href="/" className="crayons-nav-block">
      <span className="crayons-icon" role="img" aria-label="Tags">
        🏷
      </span>
      Tags
    </a>
    <a href="/" className="crayons-nav-block">
      <span className="crayons-icon" role="img" aria-label="Listings">
        📑
      </span>
      Listings
      <span className="crayons-indicator">3</span>
    </a>
    <a href="/" className="crayons-nav-block">
      <span className="crayons-icon" role="img" aria-label="Code of Conduct">
        👍
      </span>
      Code of Conduct
    </a>
    <a href="/" className="crayons-nav-block crayons-nav-block--indented">
      More...
    </a>
  </div>
);

Default.story = {
  name: 'default',
};

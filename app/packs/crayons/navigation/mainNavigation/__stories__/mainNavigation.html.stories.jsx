import { h } from 'preact';
import '../../../storybook-utilities/designSystem.scss';
import notes from './main-navigation.md';

export default {
  title: 'Components/Navigation/Main Navigation/HTML',
  parameters: { notes },
};

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

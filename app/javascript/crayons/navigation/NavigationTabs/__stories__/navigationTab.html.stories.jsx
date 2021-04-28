import { h } from 'preact';
import '../../../storybook-utilities/designSystem.scss';
import notes from './navigation-tab.md';

export default {
  title: 'Components/Navigation/Tabs/HTML',
  parameters: { notes },
};

export const Default = () => (
  <nav className="crayons-tabs">
    <ul className="crayons-tabs__list">
      <li>
        <a
          href="/"
          className="crayons-tabs__item crayons-tabs__item--current"
          aria-current="page"
        >
          Feed
        </a>
      </li>
      <li>
        <a href="/" className="crayons-tabs__item">
          Popular
        </a>
      </li>
      <li>
        <a href="/" className="crayons-tabs__item">
          Latest
        </a>
      </li>
    </ul>
  </nav>
);

Default.story = {
  name: 'default',
};

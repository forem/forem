import { h } from 'preact';
import '../../../storybook-utilities/designSystem.scss';
import notes from './navigation-tab.md';

export default {
  title: 'Components/Navigation/Tabs/HTML',
  parameters: { notes },
};

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

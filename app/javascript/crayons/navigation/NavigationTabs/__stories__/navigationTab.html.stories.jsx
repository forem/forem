import { h } from 'preact';
import '../../../storybook-utilities/designSystem.scss';
import { useState } from 'preact/hooks';
import notes from './navigation-tab.mdx';

export default {
  title: 'Components/Navigation/Tabs/HTML',
  parameters: { notes },
};

const tabs = {
  feed: 'Feed',
  popular: 'Popular',
  latest: 'Latest',
};

export const Default = () => {
  const [currentTab, setCurrentTab] = useState(
    window.location.hash.substr(1) || tabs.feed,
  );

  const tabOnClick = (tabId) => {
    setCurrentTab(tabId);
  };

  return (
    <nav className="crayons-tabs" aria-label="View feed options">
      <ul className="crayons-tabs__list">
        <li>
          <a
            data-text={tabs.feed}
            className={`crayons-tabs__item ${
              currentTab === tabs.feed ? 'crayons-tabs__item--current' : ''
            }`}
            aria-current={currentTab === tabs.feed ? 'page' : null}
            onClick={() => tabOnClick(tabs.feed)}
            href={`#${tabs.feed}`}
          >
            {tabs.feed}
          </a>
        </li>
        <li>
          <a
            data-text={tabs.popular}
            className={`crayons-tabs__item ${
              currentTab === tabs.popular ? 'crayons-tabs__item--current' : ''
            }`}
            aria-current={currentTab === tabs.popular ? 'page' : null}
            onClick={() => tabOnClick(tabs.popular)}
            href={`#${tabs.popular}`}
          >
            {tabs.popular}
          </a>
        </li>
        <li>
          <a
            data-text={tabs.latest}
            className={`crayons-tabs__item ${
              currentTab === tabs.latest ? 'crayons-tabs__item--current' : ''
            }`}
            aria-current={currentTab === tabs.latest ? 'page' : null}
            onClick={() => tabOnClick(tabs.latest)}
            href={`#${tabs.latest}`}
          >
            {tabs.latest}
          </a>
        </li>
      </ul>
    </nav>
  );
};

Default.storyName = 'default';

export const Buttons = () => (
  <nav className="crayons-tabs" aria-label="View post options">
    <ul className="crayons-tabs__list">
      <li>
        <button
          className="crayons-tabs__item crayons-tabs__item--current"
          aria-current="page"
        >
          Edit
        </button>
      </li>
      <li>
        <button className="crayons-tabs__item">Preview</button>
      </li>
    </ul>
  </nav>
);
Buttons.storyName = 'buttons';

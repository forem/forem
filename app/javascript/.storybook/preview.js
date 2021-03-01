import { h } from 'preact';
import { addDecorator, addParameters } from '@storybook/preact';
import { DocsPage, DocsContainer } from '@storybook/addon-docs/blocks';

import '../../assets/stylesheets/minimal.scss';
import '../../assets/stylesheets/views.scss';
import '../../assets/stylesheets/crayons.scss';
import '../../assets/javascripts/lib/xss';
import '../../assets/javascripts/utilities/timeAgo';
import './storybook.scss';

function addStylesheet(theme = '') {
  if (theme === '') {
    return; // default theme
  }

  const head = document.head;
  const link = document.createElement('link');

  link.type = 'text/css';
  link.rel = 'stylesheet';
  link.href = `themes/${theme}.css`;
  link.id = 'dev-theme';

  head.appendChild(link);
}

function themeSwitcher(event) {
  const themeNode = document.getElementById('dev-theme');
  const theme = event.target.value;

  if (themeNode) {
    themeNode.parentElement.removeChild(themeNode);
  }

  localStorage.setItem('storybook-crayons-theme', theme);

  addStylesheet(theme);
}

const THEMES = Object.freeze(['default', 'night', 'minimal', 'pink', 'hacker']);

const themeSwitcherDecorator = (storyFn) => {
  const lastThemeUsed = localStorage.getItem('storybook-crayons-theme') || '';

  addStylesheet(lastThemeUsed);

  return (
    <div>
      <label style={{ position: 'absolute', top: 0, left: 0, margin: '1rem' }}>
        theme{' '}
        <select onChange={themeSwitcher}>
          {THEMES.map((theme) => (
            <option
              selected={lastThemeUsed === theme}
              value={theme}
              key={theme}
            >
              {theme}
            </option>
          ))}
        </select>
      </label>
      {storyFn()}
    </div>
  );
};

addDecorator(themeSwitcherDecorator);
addDecorator((Story) => <Story />);

addParameters({
  options: {
    storySort: (a, b) =>
      a[1].kind === b[1].kind
        ? 0
        : a[1].id.localeCompare(b[1].id, undefined, { numeric: true }),
  },

  docs: {
    container: DocsContainer,
    page: DocsPage,
  },
});

export const Foo = () => <Component />;
Foo.parameters = {
  previewTabs: { 'storybook/docs/panel': { index: -1 } },
};

export const parameters = {
  options: {
    storySort: {
      order: [
        'Introduction',
        'Component Library',
        'Utility-First CSS',
        'Writing CSS',
        'Fundamentals',
        'Components',
        'App Components',
        'Utility-First Classes',
      ],
    },
  },
};

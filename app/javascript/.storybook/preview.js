import { h } from 'preact';
import { addDecorator, addParameters } from '@storybook/preact';
import { withA11y } from '@storybook/addon-a11y';

import '../../assets/stylesheets/minimal.scss';
import '../../assets/stylesheets/crayons.scss';
import '../../assets/javascripts/lib/xss';
import '../../assets/javascripts/utilities/timeAgo';
import './storybook.scss';

function addStylesheet(theme) {
  if (theme === '') {
    return; // default theme
  }

  const head = document.head;
  const link = document.createElement('link');

  link.type = 'text/css';
  link.rel = 'stylesheet';
  link.href = `themes/${event.target.value}.css`;
  link.id = 'dev-theme';

  head.appendChild(link);
}

const themeSwitcher = (event) => {
  const currentTheme = document.getElementById('dev-theme');

  if (currentTheme) {
    currentTheme.parentElement.removeChild(currentTheme);
  }

  addStylesheet(event.target.value);
};

const themeSwitcherDecorator = (storyFn) => (
  <div>
    <label style={{ position: 'absolute', top: 0, left: 0, margin: '1rem' }}>
      Theme{' '}
      <select onChange={themeSwitcher}>
        <option value="">Default</option>
        <option value="night">Night</option>
        <option value="minimal">Minimal</option>
        <option value="pink">Pink</option>
        <option value="hacker">Hacker</option>
      </select>
    </label>
    {storyFn()}
  </div>
);

addDecorator(themeSwitcherDecorator);
addDecorator(withA11y);

addParameters({
  options: {
    storySort: (a, b) =>
      a[1].kind === b[1].kind
        ? 0
        : a[1].id.localeCompare(b[1].id, undefined, { numeric: true }),
  },
});

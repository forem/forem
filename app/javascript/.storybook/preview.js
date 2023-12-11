import { h } from 'preact';
import { addDecorator, addParameters } from '@storybook/preact';
import { DocsPage, DocsContainer } from '@storybook/addon-docs';
import { jsxDecorator } from 'storybook-addon-jsx';
import cssVariablesTheme from '@etchteam/storybook-addon-css-variables-theme';
import 'focus-visible';

import '../../assets/stylesheets/minimal.scss';
import '../../assets/stylesheets/views.scss';
import '../../assets/stylesheets/crayons.scss';
import LightTheme from '!!style-loader?injectType=lazyStyleTag!css-loader!../../assets/stylesheets/config/_colors.css';
import DarkTheme from '!!style-loader?injectType=lazyStyleTag!css-loader!../../assets/stylesheets/themes/dark.css';
import '../../assets/javascripts/lib/xss';
import '../../assets/javascripts/utilities/timeAgo';
import './storybook.scss';

addDecorator(jsxDecorator);
addDecorator((Story) => <Story />);
addDecorator(cssVariablesTheme);

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

export const parameters = {
  controls: { expanded: true },
  jsx: {
    filterProps: (val) => val !== undefined,
    functionValue: (fn) => {
      fn.toString = () => '() => {}';
      return fn;
    },
  },
  cssVariables: {
    files: {
      LightTheme,
      DarkTheme,
    },
  },
  backgrounds: {
    default: 'Card',
    grid: {
      disable: true,
    },
    values: [
      {
        name: 'Card',
        value: 'var(--card-bg)',
      },
      {
        name: 'Body',
        value: 'var(--body-bg)',
      },
    ],
  },
};

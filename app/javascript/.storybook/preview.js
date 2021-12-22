import { h } from 'preact';
import { addDecorator, addParameters } from '@storybook/preact';
import { DocsPage, DocsContainer } from '@storybook/addon-docs/blocks';
import { jsxDecorator } from 'storybook-addon-jsx';
import 'focus-visible';

import '../../assets/stylesheets/minimal.scss';
import '../../assets/stylesheets/views.scss';
import '../../assets/stylesheets/crayons.scss';
import '../../assets/javascripts/lib/xss';
import '../../assets/javascripts/utilities/timeAgo';
import './storybook.scss';

addDecorator(jsxDecorator);
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

export const parameters = {
  controls: { expanded: true },
  jsx: {
    filterProps: (val) => val !== undefined,
    functionValue: (fn) => {
      fn.toString = () => '() => {}';
      return fn;
    },
  },
  html: {
    root: '#story-content',
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

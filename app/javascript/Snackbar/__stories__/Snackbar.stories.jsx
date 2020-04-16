import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import { Snackbar } from '../Snackbar';

const snackbarDecorator = (story) => (
  <div className="crayons-snackbar absolute">{story()}</div>
);

export default {
  title: 'App Components/Snackbar',
};

export const Default = () => <Snackbar>Hello world!</Snackbar>;

Default.story = {
  name: 'default',
  decorators: [snackbarDecorator],
};

export const WithOneAction = () => {
  const actions = [
    {
      text: 'Action 1',
      handler: action('Action 1 fired.'),
    },
  ];
  return <Snackbar actions={actions}>Hello world!</Snackbar>;
};

WithOneAction.story = {
  name: 'with one action',
};

export const WithMultipleActions = () => {
  const actions = [
    {
      text: 'Action 1',
      handler: action('Action 1 fired.'),
    },
    {
      text: 'Action 2',
      handler: action('Action 2 fired.'),
    },
    {
      text: 'Action 3',
      handler: action('Action 3 fired.'),
    },
  ];
  return <Snackbar actions={actions}>Hello world!</Snackbar>;
};

WithMultipleActions.story = {
  name: 'with multiple actions',
};

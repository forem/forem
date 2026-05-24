import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import faker from '@faker-js/faker';
import { Snackbar, addSnackbarItem } from '..';

export default {
  title: 'App Components/Snackbar/Snackbar',
  component: Snackbar,
  argTypes: {
    lifespan: {
      control: { type: 'number' },
      description: 'Lifespan of snackbar items in seconds',
    },
    pollingTime: {
      control: { type: 'number' },
      description: 'Polling time in milliseconds',
    },
  },
  args: {
    lifespan: 5,
    pollingTime: 300,
  },
};

export const SimulateAddingSnackbarItems = (args) => {
  addSnackbarItem({
    message: faker.hacker.phrase(),
    actions: [
      { text: faker.lorem.word(), handler: action('action 1 clicked') },
    ],
  });

  addSnackbarItem({
    message: faker.hacker.phrase(),
    actions: [
      { text: faker.lorem.word(), handler: action('action 2 clicked') },
    ],
  });

  addSnackbarItem({
    message: faker.hacker.phrase(),
    actions: [
      { text: faker.lorem.word(), handler: action('action 3 clicked') },
    ],
  });

  addSnackbarItem({
    message: faker.hacker.phrase(),
    actions: [
      { text: faker.lorem.word(), handler: action('action 3 clicked') },
    ],
  });

  return (
    <Snackbar
      lifespan={args.lifespan}
      pollingTime={args.pollingTime}
    />
  );
};

SimulateAddingSnackbarItems.storyName =
  'simulating adding multiple snackbar items';

import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import faker from 'faker';
import { number } from '@storybook/addon-knobs';
import { Snackbar, addSnackbarItem } from '..';

export default {
  title: 'App Components/Snackbar/Snackbar',
};

export const SimulateAddingSnackbarItems = () => {
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
      lifespan={number('lifespan', 5)}
      pollingTime={number('pollingTime', 300)}
    />
  );
};

SimulateAddingSnackbarItems.story = {
  name: 'simulating adding multiple snackbar items',
};

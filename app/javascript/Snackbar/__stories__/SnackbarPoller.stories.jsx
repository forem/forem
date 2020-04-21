import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import faker from 'faker';
import { number } from '@storybook/addon-knobs';
import { Snackbar, SnackbarItem, SnackbarPoller, addSnackbarItem } from '..';

export default {
  title: 'App Components/Snackbar/SnackbarPoller',
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

  return (
    <SnackbarPoller
      lifespan={number('lifespan', 5)}
      pollingTime={number('pollingTime', 300)}
    >
      {(snackbarItems) => (
        <Snackbar>
          {snackbarItems.map(({ message, actions = [] }) => (
            <SnackbarItem message={message} actions={actions} />
          ))}
        </Snackbar>
      )}
    </SnackbarPoller>
  );
};

SimulateAddingSnackbarItems.story = {
  name: 'simulating adding multiple snackbar items',
};

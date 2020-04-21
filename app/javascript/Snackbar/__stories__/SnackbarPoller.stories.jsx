import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import faker from 'faker';
import { Snackbar, SnackbarItem, SnackbarPoller, addSnackbarItem } from '..';

export default {
  title: 'App Components/Snackbar/SnackbarPoller',
};

export const SimulateAddingSnackbarItems = () => {
  setInterval(() => {
    const text = faker.lorem.word();

    addSnackbarItem({
      message: faker.hacker.phrase(),
      actions: [{ text, handler: action(text) }],
    });
  }, 2500);

  return (
    <SnackbarPoller>
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

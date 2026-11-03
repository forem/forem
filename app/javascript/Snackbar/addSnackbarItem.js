export const snackbarItems = [];

export function addSnackbarItem(snackbarItem) {
  if (!Array.isArray(snackbarItem.actions)) {
    snackbarItem.actions = []; // eslint-disable-line no-param-reassign
  }

  snackbarItems.push(snackbarItem);
}

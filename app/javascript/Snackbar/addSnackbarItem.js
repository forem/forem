export const snackbarItems =
  typeof window !== 'undefined'
    ? // eslint-disable-next-line no-multi-assign
      (window.__foremSnackbarItems = window.__foremSnackbarItems || [])
    : [];

export function addSnackbarItem(snackbarItem) {
  if (!Array.isArray(snackbarItem.actions)) {
    snackbarItem.actions = []; // eslint-disable-line no-param-reassign
  }

  snackbarItems.push(snackbarItem);
}

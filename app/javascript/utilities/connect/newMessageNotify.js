export function notifyUser() {
  modifyTitle();
}

const modifyTitle = () => {
  const oldTitle = document.title;
  const titleAlert = setInterval(() => {
    if (document.title === oldTitle) document.title = 'New Message 👋';
    else document.title = oldTitle;
  }, 2000);

  setTimeout(() => {
    clearInterval(titleAlert);
    document.title = oldTitle;
  }, 12000);
};

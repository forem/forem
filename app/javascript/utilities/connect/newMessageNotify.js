import { i18next } from '@utilities/locale';
export function notifyUser() {
  modifyTitle();
}

const modifyTitle = () => {
  const oldTitle = document.title;
  const titleAlert = setInterval(() => {
    if (document.title === oldTitle)
      document.title = i18next.t('chat.meta.title_new');
    else document.title = oldTitle;
  }, 2000);

  setTimeout(() => {
    clearInterval(titleAlert);
    document.title = oldTitle;
  }, 12000);
};

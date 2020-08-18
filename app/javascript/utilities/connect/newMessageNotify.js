export default function notifyUser() {
  modifyTitle();
  const audio = new Audio('../../../assets/sound/notification.mp3');
  audio.play();
}

const modifyTitle = () => {
  const oldTitle = document.title;
  const titleAlert = setInterval(() => {
    document.title = 'New Message 👋';
  }, 2000);
  const reset = setInterval(() => {
    document.title = oldTitle;
  }, 4000);
  setTimeout(() => {
    clearInterval(titleAlert, reset);
  }, 12000);
};

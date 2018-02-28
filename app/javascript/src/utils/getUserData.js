export function getUserData() {
  const promise = new Promise((resolve, reject) => {
    let i = 0;
    const waitingOnUserData = setInterval(() => {
      let userData = null;
      const dataUserAttribute = document.body.getAttribute('data-user');
      if (dataUserAttribute && dataUserAttribute !== 'undefined' && dataUserAttribute !== undefined) {
        userData = JSON.parse(dataUserAttribute);
      }
      i += 1;
      if (userData) {
        clearInterval(waitingOnUserData);
        resolve(userData);
      } else if (i === 3000) {
        clearInterval(waitingOnUserData);
        reject("Couldn't find user data on page.");
      }
    }, 5);
  });
  return promise;
}

export default 'getUserData';

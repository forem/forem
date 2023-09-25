export class UserStore {
  constructor() {
    this.users = [];
    this.wasFetched = false;
  }

  fetch(url) {
    const myStore = this;
    return new Promise((resolve, _reject) => {
      if (myStore.wasFetched) {
        resolve();
      } else {
        window
          .fetch(url)
          .then((res) => res.json())
          .then((data) => {
            myStore.users = data.reduce((array, aUser) => {
              array.push(aUser);
              return array;
            }, []);
            myStore.wasFetched = true;
            resolve();
          })
          .catch((error) => {
            Honeybadger.notify(error);
            resolve();
          });
      }
    });
  }

  matchingIds(arrayOfIds) {
    const allUsers = this.users;
    const someUsers = arrayOfIds.reduce((array, idString) => {
      const aUser = allUsers.find((user) => user.id == idString);
      if (typeof aUser != 'undefined') {
        array.push(aUser);
      }
      return array;
    }, []);
    return someUsers;
  }

  search(term, options) {
    options ||= {};
    const { except } = options;
    const allUsers = this.users;
    const results = [];
    for (const aUser of allUsers) {
      if (
        aUser.id != except &&
        (aUser.name.search(term) >= 0 || aUser.username.search(term) >= 0)
      ) {
        results.push(aUser);
      }
    }
    return results;
  }
}

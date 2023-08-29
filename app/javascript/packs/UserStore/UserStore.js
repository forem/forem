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
            myStore.users = data;
            myStore.wasFetched = true;
            resolve();
          });
      }
    });
  }

  matchingIds(arrayOfIds) {
    const allUsers = this.users;
    const someUsers = arrayOfIds.map((idString) => {
      const aUser = allUsers.find((user) => user.id == idString);
      return typeof aUser != 'undefined' ? aUser : null;
    });
    return someUsers;
  }

  search(term) {
    const allUsers = this.users;
    const results = [];
    for (const aUser of allUsers) {
      if (aUser.name.search(term) >= 0 || aUser.username.search(term) >= 0) {
        results.push(aUser);
      }
    }
    return results;
  }
}

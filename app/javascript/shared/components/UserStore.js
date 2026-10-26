export class UserStore {
  constructor(users = []) {
    this.users = users;
  }

  static async fetch(url) {
    try {
      const res = await window.fetch(url);
      return new UserStore(await res.json());
    } catch (error) {
      Honeybadger.notify(error);
    }
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
        (aUser.name.includes(term) || aUser.username.includes(term))
      ) {
        results.push(aUser);
      }
    }
    return results;
  }
}

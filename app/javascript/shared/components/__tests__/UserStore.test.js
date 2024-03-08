import fetch from 'jest-fetch-mock';
import { UserStore } from '../UserStore';

global.fetch = fetch;

function fakeUsers() {
  return JSON.stringify([
    { name: 'Alice', username: 'alice', id: 1 },
    { name: 'Bob', username: 'bob', id: 2 },
    { name: 'Charlie', username: 'charlie', id: 3 },
    { name: 'Almost Alice', username: 'almostalice', id: 4 },
  ]);
}

describe('UserStore', () => {
  beforeEach(() => {
    fetch.resetMocks();
    fetch.mockResponse(fakeUsers());
  });

  test('initializes with an empty user list', () => {
    const subject = new UserStore();
    expect(subject.users).toStrictEqual([]);
  });

  test('initializes with a user list', () => {
    const users = [{ name: 'Bob', username: 'bob', id: 2 }];
    const subject = new UserStore(users);
    expect(subject.users).toStrictEqual(users);
  });

  test('fetch from a given url', async () => {
    await UserStore.fetch('/path/to/the/users');
    expect(fetch).toHaveBeenCalledWith('/path/to/the/users');
  });

  test('return a sub-set of users matching given IDs', async () => {
    const subject = await UserStore.fetch('/path/to/the/users');
    expect(subject.matchingIds(['1', '4'])).toStrictEqual([
      { name: 'Alice', username: 'alice', id: 1 },
      { name: 'Almost Alice', username: 'almostalice', id: 4 },
    ]);
    expect(subject.matchingIds(['2', '3'])).toStrictEqual([
      { name: 'Bob', username: 'bob', id: 2 },
      { name: 'Charlie', username: 'charlie', id: 3 },
    ]);
  });

  test('return a sub-set of users matching search term', async () => {
    const subject = await UserStore.fetch('/path/to/the/users');
    expect(subject.search('alice')).toStrictEqual([
      { name: 'Alice', username: 'alice', id: 1 },
      { name: 'Almost Alice', username: 'almostalice', id: 4 },
    ]);
    expect(subject.search('stal')).toStrictEqual([
      { name: 'Almost Alice', username: 'almostalice', id: 4 },
    ]);
    expect(subject.search('david')).toStrictEqual([]);
  });

  test('search with an exception', async () => {
    const subject = await UserStore.fetch('/path/to/the/users');
    expect(subject.search('a', { except: '3' })).toStrictEqual([
      { name: 'Alice', username: 'alice', id: 1 },
      { name: 'Almost Alice', username: 'almostalice', id: 4 },
    ]);
  });
});

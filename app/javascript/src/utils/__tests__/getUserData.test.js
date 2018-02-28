import { getUserData } from '../getUserData';

describe('getUserData', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    document.body.setAttribute('data-user', null);
  });

  it('returns user data if available in document', async () => {
    document.body.setAttribute('data-user', '{}');
    const data = getUserData().then(d => d);
    expect(setInterval).toHaveBeenCalledTimes(1);
    expect(setInterval).toHaveBeenLastCalledWith(expect.any(Function), 5);
    jest.runOnlyPendingTimers();
    expect(clearInterval).toHaveBeenCalledTimes(1);
    await expect(data).resolves.toEqual({});
  });

  it('return error rejects if no user data is located', async () => {
    const data = getUserData().then(d => d);
    expect(setInterval).toHaveBeenCalledTimes(1);
    expect(setInterval).toHaveBeenLastCalledWith(expect.any(Function), 5);
    jest.advanceTimersByTime(200000);
    expect(clearInterval).toHaveBeenCalledTimes(1);
    await expect(data).rejects.toEqual("Couldn't find user data on page.");
  });
});

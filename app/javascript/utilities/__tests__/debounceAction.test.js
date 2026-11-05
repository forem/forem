import { debounceAction } from '../debounceAction';

describe('debounceAction', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('debounces trailing calls by default (200ms)', () => {
    const fn = jest.fn();
    const debounced = debounceAction(fn);

    debounced('a');
    debounced('b');
    expect(fn).not.toHaveBeenCalled();

    jest.advanceTimersByTime(199);
    expect(fn).not.toHaveBeenCalled();

    jest.advanceTimersByTime(1);
    expect(fn).toHaveBeenCalledTimes(1);
    expect(fn).toHaveBeenCalledWith('b');
  });

  it('supports leading execution when configured', () => {
    const fn = jest.fn();
    const debounced = debounceAction(fn, {
      time: 100,
      config: { leading: true },
    });

    debounced('first');
    expect(fn).toHaveBeenCalledTimes(1);
    expect(fn).toHaveBeenCalledWith('first');

    debounced('second');
    jest.advanceTimersByTime(100);
    expect(fn).toHaveBeenCalledTimes(2);
    expect(fn).toHaveBeenLastCalledWith('second');
  });

  it('supports cancel() and flush()', () => {
    const fn = jest.fn((val) => `res:${val}`);
    const debounced = debounceAction(fn, { time: 100 });

    debounced('cancel-me');
    debounced.cancel();
    jest.advanceTimersByTime(100);
    expect(fn).not.toHaveBeenCalled();

    debounced('flush-me');
    expect(debounced.flush()).toBe('res:flush-me');
    expect(fn).toHaveBeenCalledTimes(1);
  });

  it('respects trailing: false when flush() is called', () => {
    const fn = jest.fn((val) => `res:${val}`);
    const debounced = debounceAction(fn, {
      time: 100,
      config: { leading: true, trailing: false },
    });

    expect(debounced('first')).toBe('res:first');
    expect(fn).toHaveBeenCalledTimes(1);

    debounced('second');
    expect(debounced.flush()).toBe('res:first');
    expect(fn).toHaveBeenCalledTimes(1);
  });
});

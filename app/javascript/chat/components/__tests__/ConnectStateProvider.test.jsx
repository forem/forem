import { h } from 'preact';
import { renderHook, act } from '@testing-library/preact-hooks';
import { useContext } from 'preact/hooks';
import { store, ConnectStateProvider } from '../ConnectStateProvider';

// There is no need to test for accessibility for the store or ConnectStateProvider as they
// relate only to state management.

describe('<ConnectStateProvider />', () => {
  it('should initialize Connect state with given initialState', async () => {
    const initialState = {
      channel: {
        channelId: 1,
        channelName: 'test',
      },
      showSidecar: false,
    };

    const wrapper = ({ children }) => (
      <ConnectStateProvider
        initialState={initialState}
        reducer={(state) => state}
      >
        {children}
      </ConnectStateProvider>
    );
    const { result } = renderHook(() => useContext(store), { wrapper });

    expect(result.current.state).toEqual(initialState);
  });

  it('should dispatch an action', async () => {
    const reducer = jest.fn((state, _action) => {
      return state;
    });
    const action = { type: 'some action' };
    const initialState = {
      channel: {
        channelId: 1,
        channelName: 'test',
      },
      showSidecar: false,
    };

    const wrapper = ({ children }) => (
      <ConnectStateProvider initialState={initialState} reducer={reducer}>
        {children}
      </ConnectStateProvider>
    );

    const { result } = renderHook(() => useContext(store), { wrapper });

    act(() => {
      result.current.dispatch(action);
    });

    expect(reducer).toHaveBeenCalledTimes(1);
    expect(reducer).toHaveBeenCalledWith(initialState, action);
  });
});

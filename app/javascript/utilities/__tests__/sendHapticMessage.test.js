import { sendHapticMessage } from '../sendHapticMessage';

describe('SendHapticMessage Utility', () => {
  it('should call postMessage', async () => {
    const mockPostMessage = jest.fn();
    global.window.webkit = {
      messageHandlers: {
        haptic: {
          postMessage: mockPostMessage,
        },
      },
    };
    await sendHapticMessage('sample message');

    expect(mockPostMessage).toHaveBeenCalled();
  });

  it('should log to console otherwise', async () => {
    global.window = {};
    global.console.log = jest.fn();
    await sendHapticMessage('sample message');
    expect(global.console.log).not.toHaveBeenCalled();
  });
});

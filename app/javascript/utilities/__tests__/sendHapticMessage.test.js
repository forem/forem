import { sendHapticMessage } from "../sendHapticMessage";

describe('SendHapticMessage Utility', () => {
  beforeEach(() => {
    const mockPostMessage = jest.fn();
    global.window.webkit = { messageHandlers: {
      haptic: {
        postMessage: mockPostMessage
      }
    }};
  });

  it('should call postMessage', async () => {
    await sendHapticMessage("sample message");

    expect(mockPostMessage).toHaveBeenCalled();
  })

})
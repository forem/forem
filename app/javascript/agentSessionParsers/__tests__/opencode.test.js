import { parse } from '../opencode';

describe('opencode parser', () => {
  it('parses OpenCode CLI JSON exports', () => {
    const input = JSON.stringify({
      info: {
        id: 'ses_123',
        title: 'OpenCode session',
        directory: '/workspace/project',
        time: { created: 1778005777747, updated: 1778005780228 },
      },
      messages: [
        {
          info: {
            role: 'user',
            time: { created: 1778005777747 },
            model: { providerID: 'google', modelID: 'gemini-3-flash-preview' },
          },
          parts: [{ type: 'text', text: 'Hello OpenCode' }],
        },
        {
          info: { role: 'assistant', time: { created: 1778005780228 } },
          parts: [
            { type: 'reasoning', text: 'Thinking through the task' },
            { type: 'tool', tool: 'bash', callID: 'call_1', state: { input: { command: 'ls' }, output: 'file.txt' } },
            { type: 'text', text: 'Done' },
          ],
        },
      ],
    });

    const result = parse(input);

    expect(result.messages).toHaveLength(2);
    expect(result.messages[0].role).toBe('user');
    expect(result.messages[0].content[0].text).toBe('Hello OpenCode');
    expect(result.messages[1].role).toBe('assistant');
    expect(result.messages[1].content[1].type).toBe('tool_call');
    expect(result.messages[1].content[1].name).toBe('bash');
    expect(result.metadata.tool_name).toBe('opencode');
    expect(result.metadata.session_id).toBe('ses_123');
    expect(result.metadata.model).toBe('google/gemini-3-flash-preview');
  });

});

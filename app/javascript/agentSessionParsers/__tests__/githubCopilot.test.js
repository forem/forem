import { parse } from '../githubCopilot';

describe('githubCopilot parser', () => {
  function makeRecord(type, data = {}, extra = {}) {
    return JSON.stringify({ type, data, timestamp: '2025-01-01T00:00:00Z', ...extra });
  }

  it('parses user messages', () => {
    const input = makeRecord('user.message', { content: 'Hello world' });
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].role).toBe('user');
    expect(result.messages[0].content[0].text).toBe('Hello world');
  });

  it('parses assistant text messages', () => {
    const input = makeRecord('assistant.message', { content: 'Here is my response' });
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].role).toBe('assistant');
    expect(result.messages[0].content[0].text).toBe('Here is my response');
  });

  it('parses assistant tool requests', () => {
    const input = makeRecord('assistant.message', {
      toolRequests: [
        { name: 'readFile', arguments: '{"path": "/foo.js"}', toolCallId: 'tc1' },
      ],
    });
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].type).toBe('tool_call');
    expect(result.messages[0].content[0].name).toBe('readFile');
  });

  it('splits assistant text and tool requests into separate messages', () => {
    const input = makeRecord('assistant.message', {
      content: 'Let me read that file',
      toolRequests: [
        { name: 'readFile', arguments: '{"path": "/foo.js"}', toolCallId: 'tc1' },
      ],
    });
    const result = parse(input);
    expect(result.messages).toHaveLength(2);
    expect(result.messages[0].content[0].text).toBe('Let me read that file');
    expect(result.messages[1].content[0].type).toBe('tool_call');
  });

  it('attaches tool.execution_complete output to matching tool call', () => {
    const input = [
      makeRecord('assistant.message', {
        toolRequests: [
          { name: 'readFile', arguments: '{"path": "/foo.js"}', toolCallId: 'tc1' },
        ],
      }),
      makeRecord('tool.execution_complete', {
        toolCallId: 'tc1',
        result: { content: 'file contents here' },
      }),
    ].join('\n');
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].output).toContain('file contents here');
  });

  it('skips report_intent tool requests', () => {
    const input = makeRecord('assistant.message', {
      toolRequests: [
        { name: 'report_intent', arguments: '{}', toolCallId: 'tc0' },
        { name: 'readFile', arguments: '{"path": "/foo.js"}', toolCallId: 'tc1' },
      ],
    });
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].name).toBe('readFile');
  });

  it('extracts metadata from session.start', () => {
    const input = [
      makeRecord('session.start', {
        sessionId: 'gh-sess-1',
        startTime: '2025-01-01T00:00:00Z',
        copilotVersion: '1.2.3',
        context: { cwd: '/home/user/project' },
      }),
      makeRecord('user.message', { content: 'Hello' }),
    ].join('\n');
    const result = parse(input);
    expect(result.metadata.tool_name).toBe('github_copilot');
    expect(result.metadata.session_id).toBe('gh-sess-1');
    expect(result.metadata.start_time).toBe('2025-01-01T00:00:00Z');
    expect(result.metadata.cli_version).toBe('1.2.3');
    expect(result.metadata.working_directory).toBe('/home/user/project');
  });

  it('extracts model from tool.execution_complete', () => {
    const input = [
      makeRecord('assistant.message', {
        toolRequests: [{ name: 'shell', arguments: 'ls', toolCallId: 'tc1' }],
      }),
      makeRecord('tool.execution_complete', {
        toolCallId: 'tc1',
        model: 'gpt-4o',
        result: 'output',
      }),
    ].join('\n');
    const result = parse(input);
    expect(result.metadata.model).toBe('gpt-4o');
  });

  it('handles empty content gracefully', () => {
    const result = parse('');
    expect(result.messages).toHaveLength(0);
    expect(result.metadata.tool_name).toBe('github_copilot');
  });

  it('ignores unknown record types', () => {
    const input = [
      makeRecord('telemetry.event', { data: 'something' }),
      makeRecord('user.message', { content: 'Hello' }),
    ].join('\n');
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
  });

  it('handles detailedContent in tool result', () => {
    const input = [
      makeRecord('assistant.message', {
        toolRequests: [{ name: 'shell', arguments: 'ls', toolCallId: 'tc1' }],
      }),
      makeRecord('tool.execution_complete', {
        toolCallId: 'tc1',
        result: { detailedContent: 'detailed output here', content: 'short output' },
      }),
    ].join('\n');
    const result = parse(input);
    // detailedContent takes priority over content
    expect(result.messages[0].content[0].output).toContain('detailed output here');
  });
});

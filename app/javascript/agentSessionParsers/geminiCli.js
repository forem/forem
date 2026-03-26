import {
  parseJsonlLines, buildResult, buildMessage, textBlock, toolCallBlock,
  truncateOutput, truncateStr, MAX_JSON_NESTING,
} from './base.js';

export function parse(rawContent) {
  const data = parseData(rawContent);
  const messages = [];

  const sessionModel = (data && typeof data === 'object' && !Array.isArray(data))
    ? data.messages?.[0]?.model
    : null;

  const entries = extractEntries(data);
  for (const entry of entries) {
    const role = normalizeRole(entry.type || entry.role);
    if (!role) continue;

    if (role === 'user') {
      const blocks = extractContentBlocks(entry);
      if (blocks.length > 0) {
        messages.push(buildMessage({
          role: 'user',
          contentBlocks: blocks,
          timestamp: entry.timestamp,
          model: sessionModel,
        }));
      }
    } else {
      emitAssistantMessages(entry, messages, sessionModel);
    }
  }

  const metadata = extractMetadata(data, messages);
  return buildResult(messages, metadata);
}

function parseData(rawContent) {
  // Try JSON first, then JSONL
  try {
    return JSON.parse(rawContent);
  } catch {
    return parseJsonlLines(rawContent);
  }
}

function extractEntries(data) {
  if (Array.isArray(data)) return data;
  if (data && typeof data === 'object') {
    return data.messages || data.entries || data.conversation || [];
  }
  return [];
}

function normalizeRole(type) {
  if (!type) return null;
  switch (type.toLowerCase()) {
    case 'user':
    case 'human':
      return 'user';
    case 'gemini':
    case 'model':
    case 'assistant':
      return 'assistant';
    default:
      return null;
  }
}

function emitAssistantMessages(entry, messages, sessionModel) {
  const textBlocks = [];

  // Extract thoughts
  const thoughts = entry.thoughts;
  if (Array.isArray(thoughts) && thoughts.length > 0) {
    const summary = thoughts.map(t => `**${t.subject}**`).join(' / ');
    textBlocks.push(textBlock(summary));
  }

  // Extract main content text
  const contentBlocks = extractContentBlocks(entry);
  for (const b of contentBlocks) {
    if (b.type === 'text') textBlocks.push(b);
  }

  // Emit text message if any text content
  if (textBlocks.length > 0) {
    messages.push(buildMessage({
      role: 'assistant',
      contentBlocks: textBlocks,
      timestamp: entry.timestamp,
      model: sessionModel,
    }));
  }

  // Emit each tool call as its own message
  const toolCalls = entry.toolCalls;
  if (Array.isArray(toolCalls)) {
    for (const tc of toolCalls) {
      const name = tc.displayName || tc.name || 'tool_call';
      const input = tc.args;
      const inputStr = typeof input === 'string'
        ? truncateStr(input, 200)
        : truncateStr(JSON.stringify(input), 200);
      const output = extractToolOutput(tc);

      messages.push(buildMessage({
        role: 'assistant',
        contentBlocks: [toolCallBlock({ name, input: inputStr, output })],
        timestamp: tc.timestamp || entry.timestamp,
        model: sessionModel,
      }));
    }
  }

  // Handle inline functionCall/functionResponse in content arrays
  const toolCallContentBlocks = contentBlocks.filter(b => b.type === 'tool_call');
  for (const tcBlock of toolCallContentBlocks) {
    messages.push(buildMessage({
      role: 'assistant',
      contentBlocks: [tcBlock],
      timestamp: entry.timestamp,
      model: sessionModel,
    }));
  }
}

function extractToolOutput(toolCall) {
  const result = toolCall.result;
  if (!Array.isArray(result)) return undefined;

  const outputs = result
    .map(r => r?.functionResponse?.response?.output)
    .filter(Boolean);
  if (outputs.length === 0) return undefined;

  return truncateOutput(outputs.join('\n'));
}

function extractContentBlocks(entry) {
  const blocks = [];
  const content = entry.content || entry.parts || entry.text;

  if (typeof content === 'string') {
    if (content) blocks.push(textBlock(content));
  } else if (Array.isArray(content)) {
    for (const part of content) {
      if (typeof part === 'string') {
        blocks.push(textBlock(part));
      } else if (part && typeof part === 'object') {
        if (part.text) {
          blocks.push(textBlock(part.text));
        } else if (part.functionCall || part.tool_call) {
          const call = part.functionCall || part.tool_call;
          blocks.push(toolCallBlock({
            name: call.name,
            input: truncateStr(JSON.stringify(call.args), 200),
          }));
        } else if (part.functionResponse || part.tool_result) {
          const resp = part.functionResponse || part.tool_result;
          blocks.push(toolCallBlock({
            name: resp.name,
            output: truncateOutput(
              resp.response ? JSON.stringify(resp.response) : resp.content
            ),
          }));
        }
      }
    }
  }
  return blocks;
}

function extractMetadata(data, messages) {
  let metaObj = {};
  let sessionId = null;
  let startTime = null;
  let model = null;

  if (data && typeof data === 'object' && !Array.isArray(data)) {
    metaObj = data.metadata || data.session_metadata || {};
    sessionId = data.sessionId || metaObj.session_id;
    startTime = data.startTime || metaObj.start_time || metaObj.timestamp;
    model = data.messages?.[0]?.model;
  } else {
    sessionId = metaObj.session_id;
  }

  const meta = {
    tool_name: 'gemini_cli',
    total_messages: messages.length,
  };
  if (sessionId) meta.session_id = sessionId;
  if (startTime) meta.start_time = startTime;
  if (model) meta.model = model;

  return meta;
}

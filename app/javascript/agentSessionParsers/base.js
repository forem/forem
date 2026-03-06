export const MAX_JSON_NESTING = 50;
export const MAX_RECORDS = 50000;

export function buildResult(messages, metadata = {}) {
  const indexed = messages.map((msg, i) => ({ ...msg, index: i }));
  return { messages: indexed, metadata };
}

export function buildMessage({ role, contentBlocks, timestamp, model }) {
  const msg = { role, content: contentBlocks };
  if (timestamp) msg.timestamp = timestamp;
  if (model) msg.model = model;
  return msg;
}

export function textBlock(text) {
  return { type: 'text', text };
}

export function toolCallBlock({ name, input, output, toolCallId }) {
  const block = { type: 'tool_call', name };
  if (input != null) block.input = input;
  if (output != null) block.output = output;
  if (toolCallId != null) block.tool_call_id = toolCallId;
  return block;
}

export function truncateOutput(text) {
  return text;
}

export function truncateStr(str, maxLen) {
  if (str == null) return str;
  if (str.length <= maxLen) return str;
  return str.substring(0, maxLen) + '...';
}

export function parseJsonlLines(content) {
  const records = [];
  const lines = content.split('\n');
  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line) continue;
    try {
      const record = JSON.parse(line);
      records.push(record);
      if (records.length >= MAX_RECORDS) break;
    } catch {
      // Skip invalid JSON lines
    }
  }
  return records;
}

export function attachOutputToToolCall(messages, output, predicate) {
  for (const m of messages) {
    if (m.role !== 'assistant') continue;
    const content = m.content;
    if (!content) continue;
    for (const b of content) {
      if (b.type !== 'tool_call' || b.output != null) continue;
      if (predicate && !predicate(b)) continue;
      b.output = output;
      return;
    }
  }
}

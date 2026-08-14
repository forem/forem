import {
  parseJsonlLines, buildResult, buildMessage, textBlock, toolCallBlock,
  truncateOutput, truncateStr, attachOutputToToolCall,
} from './base.js';

export function parse(rawContent) {
  const records = parseJsonlLines(rawContent);
  const messages = [];
  let currentModel = null;

  for (const record of records) {
    switch (record.type) {
      case 'model_change':
        currentModel = record.modelId;
        break;
      case 'message': {
        const msg = record.message || {};
        const role = msg.role;
        const timestamp = record.timestamp;

        if (role === 'user') {
          const text = extractTextContent(msg.content);
          if (text) {
            messages.push(buildMessage({
              role: 'user',
              contentBlocks: [textBlock(text)],
              timestamp,
              model: currentModel,
            }));
          }
        } else if (role === 'assistant') {
          emitAssistantMessages(msg.content, messages, timestamp, currentModel);
        } else if (role === 'toolResult') {
          const output = extractTextContent(msg.content);
          if (output) {
            attachOutputToToolCall(messages, truncateOutput(output));
          }
        }
        break;
      }
    }
  }

  const metadata = extractMetadata(records, messages);
  return buildResult(messages, metadata);
}

function emitAssistantMessages(contentBlocks, messages, timestamp, model) {
  if (!Array.isArray(contentBlocks)) return;

  const textParts = [];

  for (const block of contentBlocks) {
    switch (block.type) {
      case 'thinking': {
        const text = block.thinking;
        if (text) {
          textParts.push(`**Thinking:** ${truncateStr(text, 300)}`);
        }
        break;
      }
      case 'text':
        if (block.text) textParts.push(block.text);
        break;
      case 'toolCall': {
        // Flush pending text as its own message
        if (textParts.length > 0) {
          messages.push(buildMessage({
            role: 'assistant',
            contentBlocks: [textBlock(textParts.join('\n\n'))],
            timestamp,
            model,
          }));
          textParts.length = 0;
        }

        const name = block.name || 'tool_call';
        const input = block.arguments;
        const inputStr = typeof input === 'string'
          ? truncateStr(input, 200)
          : truncateStr(JSON.stringify(input), 200);
        messages.push(buildMessage({
          role: 'assistant',
          contentBlocks: [toolCallBlock({ name, input: inputStr })],
          timestamp,
          model,
        }));
        break;
      }
    }
  }

  // Flush remaining text
  if (textParts.length > 0) {
    messages.push(buildMessage({
      role: 'assistant',
      contentBlocks: [textBlock(textParts.join('\n\n'))],
      timestamp,
      model,
    }));
  }
}

function extractTextContent(content) {
  if (typeof content === 'string') return content;
  if (Array.isArray(content)) {
    return content
      .filter(c => c.type === 'text' && c.text)
      .map(c => c.text)
      .join('\n') || '';
  }
  return '';
}

function extractMetadata(records, messages) {
  const session = records.find(r => r.type === 'session') || records[0];
  const modelChange = records.find(r => r.type === 'model_change');

  const meta = {
    tool_name: 'pi',
    total_messages: messages.length,
  };
  if (session?.id) meta.session_id = session.id;
  if (session?.timestamp) meta.start_time = session.timestamp;
  if (modelChange?.modelId) meta.model = modelChange.modelId;
  if (session?.cwd) meta.working_directory = session.cwd;

  return meta;
}

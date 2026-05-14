import {
  parseJsonlLines, buildResult, buildMessage, textBlock, toolCallBlock,
  truncateOutput, truncateStr, attachOutputToToolCall,
} from './base.js';

export function parse(rawContent) {
  const records = parseJsonlLines(rawContent);
  const messages = [];

  const sessionModel = records.find(r => r.type === 'tool.execution_complete')?.data?.model || null;

  for (const record of records) {
    switch (record.type) {
      case 'user.message': {
        const text = record.data?.content;
        if (text) {
          messages.push(buildMessage({
            role: 'user',
            contentBlocks: [textBlock(text)],
            timestamp: record.timestamp,
            model: sessionModel,
          }));
        }
        break;
      }
      case 'assistant.message':
        emitAssistantMessage(record, messages, sessionModel);
        break;
      case 'tool.execution_complete': {
        const data = record.data || {};
        const output = extractResultContent(data.result);
        const formatted = truncateOutput(output);
        const toolId = data.toolCallId;
        if (formatted) {
          attachOutputToToolCall(messages, formatted, b => b.tool_call_id === toolId);
        }
        break;
      }
    }
  }

  const metadata = extractMetadata(records, messages);
  return buildResult(messages, metadata);
}

function emitAssistantMessage(record, messages, sessionModel) {
  const data = record.data || {};
  const content = data.content;
  const toolRequests = data.toolRequests || [];

  // Emit text as its own message if present
  if (content) {
    messages.push(buildMessage({
      role: 'assistant',
      contentBlocks: [textBlock(content)],
      timestamp: record.timestamp,
      model: sessionModel,
    }));
  }

  // Emit each tool request as its own message
  for (const tr of toolRequests) {
    if (tr.name === 'report_intent') continue; // skip internal telemetry tool

    const name = tr.name || 'tool_call';
    const input = tr.arguments;
    const inputStr = typeof input === 'string'
      ? truncateStr(input, 200)
      : truncateStr(JSON.stringify(input), 200);

    messages.push(buildMessage({
      role: 'assistant',
      contentBlocks: [toolCallBlock({ name, input: inputStr, toolCallId: tr.toolCallId })],
      timestamp: record.timestamp,
      model: sessionModel,
    }));
  }
}

function extractResultContent(result) {
  if (result && typeof result === 'object' && !Array.isArray(result)) {
    return result.detailedContent || result.content || JSON.stringify(result);
  }
  if (typeof result === 'string') return result;
  return result != null ? JSON.stringify(result) : null;
}

function extractMetadata(records, messages) {
  const sessionStart = records.find(r => r.type === 'session.start');
  const data = sessionStart?.data || {};

  const meta = {
    tool_name: 'github_copilot',
    total_messages: messages.length,
  };
  if (data.sessionId) meta.session_id = data.sessionId;
  if (data.startTime || sessionStart?.timestamp) meta.start_time = data.startTime || sessionStart.timestamp;

  const modelRecord = records.find(r => r.type === 'tool.execution_complete');
  if (modelRecord?.data?.model) meta.model = modelRecord.data.model;
  if (data.copilotVersion) meta.cli_version = data.copilotVersion;
  if (data.context?.cwd) meta.working_directory = data.context.cwd;

  return meta;
}

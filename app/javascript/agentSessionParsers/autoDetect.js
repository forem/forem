// Synchronous imports for direct use
import * as claudeCode from './claudeCode.js';
import * as codex from './codex.js';
import * as geminiCli from './geminiCli.js';
import * as pi from './pi.js';
import * as githubCopilot from './githubCopilot.js';

const PARSER_MAP = {
  claude_code: claudeCode,
  codex: codex,
  gemini_cli: geminiCli,
  pi: pi,
  github_copilot: githubCopilot,
};

export function parserFor(toolName) {
  const parser = PARSER_MAP[toolName];
  if (!parser) {
    throw new Error(`Unknown agent tool: ${toolName}. Supported: ${Object.keys(PARSER_MAP).join(', ')}`);
  }
  return parser;
}

export function detectAndParse(content) {
  const toolName = detectTool(content);
  const parser = parserFor(toolName);
  const result = parser.parse(content);
  return { toolName, result };
}

export function detectTool(content) {
  // Try parsing first line as JSON
  const firstLineEnd = content.indexOf('\n');
  const firstLine = (firstLineEnd === -1 ? content : content.substring(0, firstLineEnd)).trim();

  if (firstLine.startsWith('{')) {
    try {
      const firstRecord = JSON.parse(firstLine);

      // GitHub Copilot: session.start with copilot producer
      if (firstRecord.type === 'session.start') return 'github_copilot';

      // Codex: old format has dotted types, new format has session_meta
      if (firstRecord.type && /^(thread|turn|item|event_msg)\./.test(firstRecord.type)) return 'codex';
      if (firstRecord.type === 'session_meta') return 'codex';

      // Pi: first record is {type: "session", version: N}
      if (firstRecord.type === 'session' && 'version' in firstRecord) return 'pi';

      // Gemini: has session_metadata type
      if (firstRecord.type === 'session_metadata') return 'gemini_cli';

      // JSONL-based agents (Claude Code, Pi, etc.)
      if ('sessionId' in firstRecord || 'version' in firstRecord ||
          'parentId' in firstRecord || 'parentUuid' in firstRecord ||
          'parentSession' in firstRecord) {
        return detectJsonlTool(firstRecord);
      }
    } catch {
      // Not JSON, continue detection
    }
  }

  // Try full JSON parse (Gemini CLI uses single JSON object)
  try {
    const data = JSON.parse(content);
    if (data && typeof data === 'object' && !Array.isArray(data) && !('parentId' in data)) {
      return 'gemini_cli';
    }
  } catch {
    // Not JSON
  }

  // Default fallback
  return 'claude_code';
}

function detectJsonlTool(firstRecord) {
  // Pi uses id/parentId tree structure
  if ('parentId' in firstRecord || 'parentSession' in firstRecord) return 'pi';

  // Claude Code uses parentUuid + sessionId
  if ('parentUuid' in firstRecord || 'sessionId' in firstRecord) return 'claude_code';

  return 'claude_code'; // Default for JSONL
}

const REDACTED_LABEL = '[REDACTED]';

// All 81 patterns ported from Ruby's SensitiveDataScrubber
const PATTERNS = [
  // === Cloud provider keys ===
  { name: 'AWS Access Key',
    regex: /(?<![A-Z0-9])(A3T[A-Z0-9]|AKIA|AGPA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}(?![A-Z0-9])/g },
  { name: 'AWS Secret Key',
    regex: /(?<=[\s:='"])[A-Za-z0-9/+=]{40}(?=[\s'"&])/g,
    context: /aws[_\s]?secret/i },
  { name: 'AWS MWS Key',
    regex: /amzn\.mws\.[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/g },
  { name: 'AWS AppSync Key',
    regex: /da2-[a-z0-9]{26}/g },
  { name: 'Google API Key',
    regex: /AIza[0-9A-Za-z\-_]{35}/g },
  { name: 'Google OAuth Token',
    regex: /ya29\.[0-9A-Za-z\-_]+/g },
  { name: 'GCP Service Account',
    regex: /"type"\s*:\s*"service_account"/g },

  // === Code hosting & CI/CD ===
  { name: 'GitHub Token',
    regex: /(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{36,}/g },
  { name: 'GitHub Fine-Grained Token',
    regex: /github_pat_[A-Za-z0-9_]{22,}/g },
  { name: 'GitLab Token',
    regex: /glpat-[A-Za-z0-9\-_]{20,}/g },
  { name: 'Bitbucket Token',
    regex: /ATBB[A-Za-z0-9]{32,}/g },
  { name: 'CircleCI Token',
    regex: /circle-token\s*[=:]\s*[A-Za-z0-9]{40}/g },
  { name: 'Travis CI Token',
    regex: /travis-token\s*[=:]\s*[A-Za-z0-9]{22}/g },
  { name: 'Heroku API Key',
    regex: /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/g,
    context: /heroku/i },
  { name: 'Vercel Token',
    regex: /vercel_[A-Za-z0-9]{24}/g },
  { name: 'Netlify Token',
    regex: /netlify_[A-Za-z0-9]{40,}/g },

  // === Payment & SaaS ===
  { name: 'Stripe Secret Key',
    regex: /[sr]k_live_[A-Za-z0-9]{20,}/g },
  { name: 'Stripe Publishable Key',
    regex: /pk_live_[A-Za-z0-9]{20,}/g },
  { name: 'Stripe Restricted Key',
    regex: /rk_live_[A-Za-z0-9]{20,}/g },
  { name: 'PayPal Token',
    regex: /access_token\$production\$[A-Za-z0-9]{16}\$[A-Za-z0-9]{32}/g },
  { name: 'Square Access Token',
    regex: /sq0atp-[A-Za-z0-9\-_]{22}/g },
  { name: 'Square OAuth Secret',
    regex: /sq0csp-[A-Za-z0-9\-_]{43}/g },

  // === Communication ===
  { name: 'Slack Token',
    regex: /xox[bpas]-[0-9]{10,}-[A-Za-z0-9\-]+/g },
  { name: 'Slack Webhook',
    regex: /https:\/\/hooks\.slack\.com\/services\/T[A-Z0-9]+\/B[A-Z0-9]+\/[A-Za-z0-9]+/g },
  { name: 'Discord Token',
    regex: /[MN][A-Za-z\d]{23,}\.[\w-]{6}\.[\w-]{27,}/g },
  { name: 'Twilio API Key',
    regex: /SK[a-f0-9]{32}/g },
  { name: 'SendGrid API Key',
    regex: /SG\.[A-Za-z0-9\-_]{22}\.[A-Za-z0-9\-_]{43}/g },
  { name: 'Mailgun API Key',
    regex: /key-[A-Za-z0-9]{32}/g,
    context: /mailgun/i },

  // === AI/ML ===
  { name: 'OpenAI API Key',
    regex: /sk-[A-Za-z0-9]{20}T3BlbkFJ[A-Za-z0-9]{20}/g },
  { name: 'OpenAI Project Key',
    regex: /sk-proj-[A-Za-z0-9\-_]{40,}/g },
  { name: 'Anthropic API Key',
    regex: /sk-ant-[A-Za-z0-9\-_]{40,}/g },
  { name: 'HuggingFace Token',
    regex: /hf_[A-Za-z0-9]{34}/g },

  // === Database & infrastructure ===
  { name: 'Database URL',
    regex: /(postgres|mysql|mongodb|redis|amqp):\/\/[^\s"'`<>]+@[^\s"'`<>]+/g },
  { name: 'JDBC Connection',
    regex: /jdbc:[a-z]+:\/\/[^\s"'`<>]+/g },
  { name: 'Firebase URL',
    regex: /https:\/\/[a-z0-9-]+\.firebaseio\.com/g },
  { name: 'Firebase Key',
    regex: /AAAA[A-Za-z0-9_-]{7}:[A-Za-z0-9_-]{140}/g },

  // === Private keys ===
  { name: 'RSA Private Key',
    regex: /-----BEGIN RSA PRIVATE KEY-----/g },
  { name: 'DSA Private Key',
    regex: /-----BEGIN DSA PRIVATE KEY-----/g },
  { name: 'EC Private Key',
    regex: /-----BEGIN EC PRIVATE KEY-----/g },
  { name: 'OpenSSH Private Key',
    regex: /-----BEGIN OPENSSH PRIVATE KEY-----/g },
  { name: 'PGP Private Key',
    regex: /-----BEGIN PGP PRIVATE KEY BLOCK-----/g },
  { name: 'Generic Private Key',
    regex: /-----BEGIN PRIVATE KEY-----/g },

  // === Generic secret patterns ===
  { name: 'Bearer Token',
    regex: /Bearer\s+[A-Za-z0-9\-_.]{20,}/g },
  { name: 'Basic Auth Header',
    regex: /Basic\s+[A-Za-z0-9+/=]{20,}/g },
  { name: 'JWT Token',
    regex: /eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/g },
  { name: 'Hex Secret (32+)',
    regex: /(?:secret|token|key|password|passwd|pwd|api_key|apikey|auth)\s*[=:]\s*["']?[A-Fa-f0-9]{32,}["']?/gi },
  { name: 'Base64 Secret',
    regex: /(?:secret|token|key|password|passwd|pwd|api_key|apikey|auth)\s*[=:]\s*["']?[A-Za-z0-9+/]{40,}={0,2}["']?/gi },

  // === PII & paths ===
  { name: 'Home Directory',
    regex: /(?:\/Users\/|\/home\/|C:\\Users\\)[A-Za-z0-9._-]+/gi },
  { name: 'Email Address',
    regex: /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z]{2,}\b/gi },
  { name: 'IPv4 Address',
    regex: /\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\b/g },
  { name: 'SSH Connection',
    regex: /ssh\s+[A-Za-z0-9._-]+@[A-Za-z0-9._-]+/g },
];

const SKIP_IN_TOOL_OUTPUT = new Set(['Home Directory', 'IPv4 Address', 'Email Address']);

export function scrub(normalizedData) {
  const data = deepClone(normalizedData);
  const redactionCounts = {};

  const messages = data.messages || [];
  for (const msg of messages) {
    scrubMessage(msg, redactionCounts);
  }

  const redactions = Object.entries(redactionCounts)
    .sort((a, b) => b[1] - a[1])
    .map(([name, count]) => ({ pattern_name: name, match_count: count }));

  return { scrubbed_data: data, redactions };
}

export function scrubText(text) {
  for (const pattern of PATTERNS) {
    if (pattern.context && !pattern.context.test(text)) continue;
    // Reset regex lastIndex for global patterns
    pattern.regex.lastIndex = 0;
    text = text.replace(pattern.regex, REDACTED_LABEL);
  }
  return text;
}

function scrubMessage(message, redactionCounts) {
  const content = message.content || [];
  for (const block of content) {
    const isToolOutput = block.type === 'tool_call';

    if (block.text) {
      block.text = scrubTextField(block.text, false, redactionCounts);
    }
    if (block.input) {
      block.input = scrubTextField(String(block.input), isToolOutput, redactionCounts);
    }
    if (block.output) {
      block.output = scrubTextField(String(block.output), true, redactionCounts);
    }
  }
}

function scrubTextField(text, isToolOutput, redactionCounts) {
  for (const pattern of PATTERNS) {
    if (isToolOutput && SKIP_IN_TOOL_OUTPUT.has(pattern.name)) continue;
    if (pattern.context && !pattern.context.test(text)) continue;

    // Reset regex lastIndex for global patterns
    pattern.regex.lastIndex = 0;
    text = text.replace(pattern.regex, () => {
      redactionCounts[pattern.name] = (redactionCounts[pattern.name] || 0) + 1;
      return REDACTED_LABEL;
    });
  }
  return text;
}

function deepClone(obj) {
  if (obj === null || typeof obj !== 'object') return obj;
  if (Array.isArray(obj)) return obj.map(deepClone);
  const cloned = {};
  for (const key of Object.keys(obj)) {
    cloned[key] = deepClone(obj[key]);
  }
  return cloned;
}

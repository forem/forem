module AgentSessionParsers
  class SensitiveDataScrubber
    REDACTED_LABEL = "[REDACTED]".freeze

    # High-confidence patterns for secrets commonly found in coding agent sessions.
    # Curated from https://github.com/mazen160/secrets-patterns-db and supplemented
    # with patterns for home directories, connection strings, and generic secrets.
    PATTERNS = [
      # === Cloud provider keys ===
      { name: "AWS Access Key", regex: /(?<![A-Z0-9])(A3T[A-Z0-9]|AKIA|AGPA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}(?![A-Z0-9])/ },
      { name: "AWS Secret Key", regex: /(?<=[\s:='""])[A-Za-z0-9\/+=]{40}(?=[\s'""&])/, context: /aws[_\s]?secret/i },
      { name: "AWS MWS Key", regex: /amzn\.mws\.[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/ },
      { name: "AWS AppSync Key", regex: /da2-[a-z0-9]{26}/ },
      { name: "Google API Key", regex: /AIza[0-9A-Za-z\-_]{35}/ },
      { name: "Google OAuth Token", regex: /ya29\.[0-9A-Za-z\-_]+/ },
      { name: "GCP Service Account", regex: /"type"\s*:\s*"service_account"/ },

      # === Code hosting & CI/CD ===
      { name: "GitHub Token", regex: /(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{36,}/ },
      { name: "GitHub Fine-Grained Token", regex: /github_pat_[A-Za-z0-9_]{22,}/ },
      { name: "GitLab Token", regex: /glpat-[A-Za-z0-9\-_]{20,}/ },
      { name: "Bitbucket Token", regex: /ATBB[A-Za-z0-9]{32,}/ },
      { name: "CircleCI Token", regex: /circle-token\s*[=:]\s*[A-Za-z0-9]{40}/ },
      { name: "Travis CI Token", regex: /travis-token\s*[=:]\s*[A-Za-z0-9]{22}/ },
      { name: "Heroku API Key", regex: /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/, context: /heroku/i },
      { name: "Vercel Token", regex: /vercel_[A-Za-z0-9]{24}/ },
      { name: "Netlify Token", regex: /netlify_[A-Za-z0-9]{40,}/ },

      # === Payment & SaaS ===
      { name: "Stripe Secret Key", regex: /[sr]k_live_[A-Za-z0-9]{20,}/ },
      { name: "Stripe Publishable Key", regex: /pk_live_[A-Za-z0-9]{20,}/ },
      { name: "Stripe Restricted Key", regex: /rk_live_[A-Za-z0-9]{20,}/ },
      { name: "PayPal Token", regex: /access_token\$production\$[A-Za-z0-9]{16}\$[A-Za-z0-9]{32}/ },
      { name: "Square Access Token", regex: /sq0atp-[A-Za-z0-9\-_]{22}/ },
      { name: "Square OAuth Secret", regex: /sq0csp-[A-Za-z0-9\-_]{43}/ },

      # === Communication ===
      { name: "Slack Token", regex: /xox[bpas]-[0-9]{10,}-[A-Za-z0-9\-]+/ },
      { name: "Slack Webhook", regex: %r{https://hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[A-Za-z0-9]+} },
      { name: "Discord Token", regex: /[MN][A-Za-z\d]{23,}\.[\w-]{6}\.[\w-]{27,}/ },
      { name: "Twilio API Key", regex: /SK[a-f0-9]{32}/ },
      { name: "SendGrid API Key", regex: /SG\.[A-Za-z0-9\-_]{22}\.[A-Za-z0-9\-_]{43}/ },
      { name: "Mailgun API Key", regex: /key-[A-Za-z0-9]{32}/, context: /mailgun/i },

      # === AI/ML ===
      { name: "OpenAI API Key", regex: /sk-[A-Za-z0-9]{20}T3BlbkFJ[A-Za-z0-9]{20}/ },
      { name: "OpenAI Project Key", regex: /sk-proj-[A-Za-z0-9\-_]{40,}/ },
      { name: "Anthropic API Key", regex: /sk-ant-[A-Za-z0-9\-_]{40,}/ },
      { name: "HuggingFace Token", regex: /hf_[A-Za-z0-9]{34}/ },

      # === Database & infrastructure ===
      { name: "Database URL", regex: %r{(postgres|mysql|mongodb|redis|amqp)://[^\s"'`<>]+@[^\s"'`<>]+} },
      { name: "JDBC Connection", regex: %r{jdbc:[a-z]+://[^\s"'`<>]+} },
      { name: "Firebase URL", regex: %r{https://[a-z0-9-]+\.firebaseio\.com} },
      { name: "Firebase Key", regex: /AAAA[A-Za-z0-9_-]{7}:[A-Za-z0-9_-]{140}/ },

      # === Private keys ===
      { name: "RSA Private Key", regex: /-----BEGIN RSA PRIVATE KEY-----/ },
      { name: "DSA Private Key", regex: /-----BEGIN DSA PRIVATE KEY-----/ },
      { name: "EC Private Key", regex: /-----BEGIN EC PRIVATE KEY-----/ },
      { name: "OpenSSH Private Key", regex: /-----BEGIN OPENSSH PRIVATE KEY-----/ },
      { name: "PGP Private Key", regex: /-----BEGIN PGP PRIVATE KEY BLOCK-----/ },
      { name: "Generic Private Key", regex: /-----BEGIN PRIVATE KEY-----/ },

      # === Generic secret patterns ===
      { name: "Bearer Token", regex: /Bearer\s+[A-Za-z0-9\-_\.]{20,}/ },
      { name: "Basic Auth Header", regex: %r{Basic\s+[A-Za-z0-9+/=]{20,}} },
      { name: "JWT Token", regex: /eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/ },
      { name: "Hex Secret (32+)", regex: /(?:secret|token|key|password|passwd|pwd|api_key|apikey|auth)\s*[=:]\s*["']?[A-Fa-f0-9]{32,}["']?/i },
      { name: "Base64 Secret", regex: /(?:secret|token|key|password|passwd|pwd|api_key|apikey|auth)\s*[=:]\s*["']?[A-Za-z0-9+\/]{40,}={0,2}["']?/i },

      # === PII & paths ===
      { name: "Home Directory", regex: %r{(?:/Users/|/home/|C:\\Users\\)[A-Za-z0-9._-]+}i },
      { name: "Email Address", regex: /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z]{2,}\b/i },
      { name: "IPv4 Address", regex: /\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\b/ },
      { name: "SSH Connection", regex: /ssh\s+[A-Za-z0-9._-]+@[A-Za-z0-9._-]+/ },
    ].freeze

    # Patterns that are too noisy for agent sessions — skip these in tool output.
    # Home dirs and IPs are common in build output and paths and aren't truly sensitive
    # when they appear inside tool_call output blocks.
    SKIP_IN_TOOL_OUTPUT = Set.new(["Home Directory", "IPv4 Address", "Email Address"]).freeze

    Result = Struct.new(:scrubbed_data, :redactions, keyword_init: true)
    Redaction = Struct.new(:pattern_name, :count, keyword_init: true)

    def self.scrub(normalized_data)
      new(normalized_data).scrub
    end

    # Scrub a plain text string (used for raw_data)
    def self.scrub_text(text)
      PATTERNS.each do |pattern|
        if pattern[:context]
          next unless text.match?(pattern[:context])
        end
        text = text.gsub(pattern[:regex], REDACTED_LABEL)
      end
      text
    end

    def initialize(normalized_data)
      @data = deep_dup(normalized_data)
      @redaction_counts = Hash.new(0)
    end

    def scrub
      messages = @data["messages"] || []
      messages.each { |msg| scrub_message(msg) }

      redactions = @redaction_counts
        .sort_by { |_, count| -count }
        .map { |name, count| Redaction.new(pattern_name: name, count: count) }

      Result.new(scrubbed_data: @data, redactions: redactions)
    end

    private

    def scrub_message(message)
      (message["content"] || []).each do |block|
        is_tool_output = block["type"] == "tool_call"

        if block["text"]
          block["text"] = scrub_text(block["text"], tool_output: false)
        end

        if block["input"]
          block["input"] = scrub_text(block["input"].to_s, tool_output: is_tool_output)
        end

        if block["output"]
          block["output"] = scrub_text(block["output"].to_s, tool_output: true)
        end
      end
    end

    def scrub_text(text, tool_output: false)
      PATTERNS.each do |pattern|
        next if tool_output && SKIP_IN_TOOL_OUTPUT.include?(pattern[:name])

        # If pattern has a context requirement, skip unless context matches
        if pattern[:context]
          next unless text.match?(pattern[:context])
        end

        text = text.gsub(pattern[:regex]) do |match|
          @redaction_counts[pattern[:name]] += 1
          "#{REDACTED_LABEL}"
        end
      end

      text
    end

    def deep_dup(obj)
      case obj
      when Hash then obj.transform_values { |v| deep_dup(v) }
      when Array then obj.map { |v| deep_dup(v) }
      when String then obj.dup
      else obj
      end
    end
  end
end

Vendored WAF rules originate from https://github.com/datadog/appsec-event-rules

One should check rule compatibility with libddwaf, which is the end consumer of
these rules.

There might be rules that look to be irrelevant to Ruby as they may still help
identify bad actors.

---
title: FAQs
---

# Frequently Asked Questions

## How do I build my local copy of the Ruby source code documentation?

```shell
cd docs
make ruby-doc
```

Then open `.static/ruby-doc/index.html` in the `docs` directory and browse the
Ruby documentation

## How do I enable logging to standard output in development?

By default Rails logs to `log.development.log`.

If, instead, you wish to log to `STDOUT` you can add the variable:

```yaml
RAILS_LOG_TO_STDOUT: true
```

to your own `config/application.yml` file.

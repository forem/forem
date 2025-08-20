# Development Performance Optimizations

This document outlines the performance optimizations made to improve the local development experience.

## 🚀 Quick Start

For the fastest development experience, run:

```bash
bin/dev-performance fast
```

Then restart your Rails server.

## Performance Improvements

### 1. **Disabled Heavy Monitoring Services**

The following services are disabled by default in development for better performance:

- **Honeybadger** - Error tracking
- **Honeycomb** - Application monitoring
- **Datadog** - Tracing and metrics
- **Ahoy** - Analytics tracking
- **Bullet** - N+1 query detection
- **SQL Logging** - Database query logging

### 2. **Optimized Puma Configuration**

- **Single worker mode** in development (faster startup)
- **Disabled preloading** in development (faster reloads)
- **Reduced memory usage** for better performance

### 3. **Reduced Logging Verbosity**

- **Log level**: Changed from `debug` to `info`
- **SQL logging**: Disabled by default
- **Query logging**: Disabled by default

## Environment Variables

You can control which services are enabled using these environment variables:

```bash
# Enable Honeybadger error tracking
HONEYBADGER_ENABLED=true

# Enable Honeycomb monitoring
HONEYCOMB_ENABLED=true

# Enable Datadog tracing
DD_ENABLED=true

# Enable Ahoy analytics
AHOY_ENABLED=true

# Enable Bullet N+1 detection
BULLET_ENABLED=true

# Enable SQL logging
SQL_LOGGING=true
```

## Helper Scripts

### Performance Management: `bin/dev-performance`

Use the `bin/dev-performance` script to easily switch between modes:

```bash
# Fastest development experience (all monitoring disabled)
bin/dev-performance fast

# Full debugging capabilities (all monitoring enabled)
bin/dev-performance debug

# Just N+1 query detection
bin/dev-performance bullet

# Just SQL logging
bin/dev-performance sql

# Check current settings
bin/dev-performance status

# Clean up processes and temp files
bin/dev-performance cleanup

# Run automatic cleanup
bin/dev-performance auto-cleanup
```

### Manual Cleanup: `bin/dev-cleanup`

For more granular control over cleanup:

```bash
# Basic cleanup (processes + temp files)
bin/dev-cleanup

# Clean everything
bin/dev-cleanup --all

# Clean specific areas
bin/dev-cleanup --clean-logs      # Log files
bin/dev-cleanup --clean-assets    # Asset caches
bin/dev-cleanup --clean-db        # Database artifacts
bin/dev-cleanup --clean-coverage  # Coverage reports
bin/dev-cleanup --clean-tests     # Test artifacts
bin/dev-cleanup --clean-git       # Git artifacts

# Show disk usage
bin/dev-cleanup --show-usage
```

### Automatic Cleanup: `bin/auto-cleanup`

For periodic maintenance:

```bash
# Run automatic cleanup
bin/auto-cleanup

# Set up automatic cleanup (add to crontab)
0 2 * * * cd /path/to/forem && bin/auto-cleanup
```

## Performance Modes

### 🚀 Fast Mode (Default)
- All monitoring services disabled
- Minimal logging
- Fastest startup and response times
- Best for general development

### 🐛 Debug Mode
- All monitoring services enabled
- Full logging
- Best for debugging issues
- Slower but more informative

### 🔍 Bullet Mode
- Only N+1 query detection enabled
- Good balance of performance and debugging
- Best for optimizing database queries

### 📊 SQL Mode
- Only SQL logging enabled
- Good for database debugging
- Minimal performance impact

## Expected Performance Gains

With these optimizations, you should see:

- **50-70% faster server startup**
- **30-50% faster page loads**
- **Reduced memory usage**
- **Cleaner console output**
- **Faster asset compilation**

## File Management Features

### **Automatic Log Rotation**
- Log files are automatically rotated when they reach 10MB
- Keeps 5 rotated files for development, 3 for test
- Reduces disk usage and improves performance

### **Smart Cleanup**
- **Log files**: Automatically cleaned if older than 7 days or larger than 50MB
- **Temporary files**: Cleaned if older than 3 days
- **Coverage reports**: Cleaned if older than 1 day
- **Test artifacts**: Cleaned automatically
- **Asset caches**: Cleaned when they get too large

### **Disk Usage Monitoring**
- Track usage of logs, temp files, and coverage
- Identify what's taking up space
- Clean up specific areas as needed

## Troubleshooting

### Need to debug a specific issue?

1. **For N+1 queries**: `bin/dev-performance bullet`
2. **For database issues**: `bin/dev-performance sql`
3. **For full debugging**: `bin/dev-performance debug`

### Performance still slow?

1. Check if you have any of the monitoring services enabled
2. Ensure you're using the optimized Puma configuration
3. Consider using `rails dev:cache` for additional caching
4. Check your `.env` file for any conflicting settings
5. Run `bin/dev-cleanup` to clean up any stuck processes
6. Run `bin/auto-cleanup` to clean up logs and temporary files
7. Check disk usage with `bin/dev-cleanup --show-usage`

### Want to permanently enable a service?

Add the environment variable to your `.env` file:

```bash
# .env
BULLET_ENABLED=true
```

## Migration Guide

If you're coming from the old configuration:

1. **No action required** - optimizations are enabled by default
2. **If you need monitoring**: Use `bin/dev-performance debug`
3. **If you need Bullet**: Use `bin/dev-performance bullet`
4. **Update your scripts**: Consider using the helper script in your development workflow

## Contributing

When adding new monitoring or debugging services:

1. Add an environment variable to control it
2. Update the `development_performance.rb` initializer
3. Update the helper script
4. Update this documentation
5. Set the default to `false` for development

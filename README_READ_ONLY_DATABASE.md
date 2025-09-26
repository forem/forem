# Read-Only Database Support

This application now supports using a separate read-only database for executing user queries. This provides better security, performance, and scalability for user query operations.

## Overview

The read-only database feature allows you to:
- Execute user queries against a read-only database replica
- Reduce load on the main database
- Improve security by using a database user with SELECT-only permissions
- Scale read operations independently from write operations

## Configuration

### Environment Variables

Set the following environment variable to enable read-only database support:

```bash
READ_ONLY_DATABASE_URL=postgres://username:password@host:port/database_name
```

### Optional Configuration

- `READ_ONLY_DATABASE_POOL_SIZE` - Connection pool size (default: 5)
- `READ_ONLY_STATEMENT_TIMEOUT` - Query timeout in milliseconds (default: 30000)

### Example Configuration

```bash
# Production example
READ_ONLY_DATABASE_URL=postgres://readonly_user:secure_password@readonly-db.example.com:5432/forem_readonly
READ_ONLY_DATABASE_POOL_SIZE=10
READ_ONLY_STATEMENT_TIMEOUT=60000
```

## Database Setup

### 1. Create Read-Only Database User

```sql
-- Create a read-only user
CREATE USER readonly_user WITH PASSWORD 'secure_password';

-- Grant connect permission
GRANT CONNECT ON DATABASE your_database TO readonly_user;

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO readonly_user;

-- Grant SELECT on all tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

-- Grant SELECT on future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly_user;
```

### 2. Set Up Database Replication (Recommended)

For production environments, set up a read replica:

```bash
# Using PostgreSQL streaming replication
# This is database-specific and depends on your setup
```

## Usage

### Automatic Fallback

If the `READ_ONLY_DATABASE_URL` environment variable is not set, the system automatically falls back to using the main database for user queries.

### Admin Interface

Access the read-only database status at `/admin/read_only_database` to:
- Check connection status
- View connection information
- Test the connection
- Reset the connection pool

### Rake Tasks

```bash
# Check read-only database health
bundle exec rake read_only_database:health_check

# Test with a simple query
bundle exec rake read_only_database:test_query

# Reset connection pool
bundle exec rake read_only_database:reset_pool
```

## Security Considerations

1. **Database User Permissions**: The read-only database user should have SELECT permissions only
2. **Network Security**: Use SSL connections and restrict network access
3. **Password Security**: Use strong, unique passwords for the read-only database user
4. **Regular Updates**: Keep the read-only database in sync with the main database

## Performance Benefits

1. **Reduced Load**: User queries don't impact main database performance
2. **Better Caching**: Read-only databases can be optimized for read operations
3. **Geographic Distribution**: Read-only databases can be placed closer to users
4. **Independent Scaling**: Scale read and write operations separately

## Monitoring

The system provides logging for read-only database usage:

```
# Debug logs show which database is being used
"Using read-only database for user query execution"
"Read-only database not configured, using main database for user query execution"
```

## Troubleshooting

### Connection Issues

1. Check the `READ_ONLY_DATABASE_URL` format
2. Verify database user permissions
3. Test network connectivity
4. Check firewall rules

### Performance Issues

1. Monitor connection pool usage
2. Adjust `READ_ONLY_DATABASE_POOL_SIZE` if needed
3. Check database replication lag
4. Monitor query performance

### Health Checks

Use the admin interface or rake tasks to monitor:
- Connection status
- Query execution success
- Connection pool health

## Migration from Main Database

If you're currently using the main database for user queries, the migration is seamless:

1. Set up the read-only database
2. Configure the environment variable
3. The system will automatically start using the read-only database
4. No code changes required

## Support

For issues or questions about the read-only database feature:
1. Check the admin interface at `/admin/read_only_database`
2. Review the logs for connection errors
3. Use the rake tasks for testing
4. Consult the database administrator for setup issues

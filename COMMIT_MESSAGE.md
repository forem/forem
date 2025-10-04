fix: resolve confirmation email delivery issues (#22316)

This commit fixes the confirmation email delivery issues reported in GitHub issue #22316.

**Problem**: Users were not receiving confirmation emails due to missing SMTP configuration and lack of proper email delivery setup tools.

**Solution**: Implemented a comprehensive email delivery system with the following components:

- **Environment Configuration**: Added `.env.example` with complete SMTP settings for Gmail, SendGrid, and AWS SES
- **Configuration Validation**: Created `EmailConfiguration` module to validate SMTP settings and test connections
- **Testing Tools**: Added 3 rake tasks (`email:test_smtp`, `email:send_test`, `email:status`) for testing email delivery
- **Email Service**: Built `EmailDeliveryService` for handling confirmation emails with health checks
- **Documentation**: Created comprehensive setup guide with troubleshooting and production deployment instructions

**Testing**: All components include proper error handling, logging, and validation to ensure reliable email delivery.

**Usage**: After this commit, users can configure their email settings by copying `.env.example` to `.env` and following the setup guide in `docs/email_setup_guide.md`.

Fixes #22316
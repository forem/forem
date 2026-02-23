# Forem Email Setup Guide

## Overview
This guide helps you set up email delivery for Forem, ensuring confirmation emails and other notifications work correctly.

## Quick Start

### 1. Environment Configuration
Copy the example environment file:
```bash
cp .env.example .env
```

Edit `.env` with your email service details:

#### Option A: Gmail SMTP (Recommended for development)
```bash
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USER_NAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_DOMAIN=yourdomain.com
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS=true
```

#### Option B: SendGrid (Recommended for production)
```bash
SENDGRID_API_KEY=your-sendgrid-api-key
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER_NAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
SMTP_DOMAIN=yourdomain.com
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS=true
```

### 2. Test Email Configuration
Run the email configuration test:
```bash
bundle exec rake email:test_smtp
```

### 3. Send Test Email
```bash
bundle exec rake email:send_test TEST_EMAIL_RECIPIENT=your-email@example.com
```

### 4. Check Email Status
```bash
bundle exec rake email:status
```

## Verification Steps

### Step 1: Configuration Validation
- [ ] Environment variables are set in `.env`
- [ ] SMTP settings are correctly configured
- [ ] Email service credentials are valid

### Step 2: Connectivity Testing
- [ ] SMTP server responds to connection attempts
- [ ] TLS/SSL certificates are valid
- [ ] Authentication succeeds

### Step 3: Email Delivery Testing
- [ ] Test email is successfully sent
- [ ] Email appears in recipient's inbox
- [ ] Email formatting is correct

### Step 4: User Registration Flow
- [ ] New user registration triggers confirmation email
- [ ] Confirmation link in email works correctly
- [ ] User account is activated after confirmation

## Troubleshooting

### Common Issues

#### 1. "No email received"
- Check spam/junk folder
- Verify SMTP credentials
- Test with `email:send_test` rake task

#### 2. "SMTP connection failed"
- Check firewall settings
- Verify SMTP server address and port
- Ensure TLS/SSL is properly configured

#### 3. "Authentication failed"
- Verify username and password
- Check if app-specific password is required (Gmail)
- Ensure authentication method matches provider requirements

#### 4. "Email not sent in development"
- Check if `SMTP_ADDRESS` is set
- Verify `ForemInstance.smtp_enabled?` returns true
- Check Sidekiq queue status

### Debugging Commands

#### Check current email configuration
```ruby
# In Rails console
EmailDeliveryService.health_check
```

#### Test email delivery manually
```ruby
# In Rails console
EmailDeliveryService.test_email_configuration
```

#### View email logs
```bash
# Check Sidekiq logs for email processing
tail -f log/sidekiq.log | grep -i mail

# Check application logs
tail -f log/development.log | grep -i email
```

## Production Deployment

### 1. Email Service Selection
- **SendGrid**: Recommended for production
- **Amazon SES**: Good for AWS deployments
- **Mailgun**: Alternative option

### 2. DNS Configuration
- Set up SPF records for your domain
- Configure DKIM if supported by your email service
- Set up DMARC policy

### 3. Monitoring Setup
- Monitor email delivery rates
- Set up alerts for failed deliveries
- Track bounce rates and spam complaints

### 4. Security Best Practices
- Use app-specific passwords for Gmail
- Store credentials in environment variables (never in code)
- Use HTTPS for all email links
- Implement rate limiting for email sending

## Service-Specific Instructions

### Gmail SMTP Setup
1. Enable 2-factor authentication on your Google account
2. Generate an app-specific password
3. Use the app password as SMTP_PASSWORD

### SendGrid Setup
1. Create a SendGrid account
2. Generate an API key with full access
3. Verify your domain in SendGrid
4. Configure DNS records as instructed by SendGrid

### Amazon SES Setup
1. Verify your domain in SES
2. Create SMTP credentials
3. Request production access if needed
4. Configure bounce and complaint handling

## Testing Checklist

Before going live, verify:

- [ ] Environment variables are set on production server
- [ ] DNS records are properly configured
- [ ] Email service is properly authenticated
- [ ] Test emails are delivered successfully
- [ ] User registration flow works end-to-end
- [ ] Email templates render correctly
- [ ] Links in emails point to correct domain
- [ ] Rate limiting is configured appropriately

## Support

If you continue to experience issues:
1. Check the troubleshooting section above
2. Review application logs for specific error messages
3. Test with the provided rake tasks
4. Consult your email service provider's documentation
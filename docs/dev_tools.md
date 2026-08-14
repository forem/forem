# Forem Developer Tools

Forem ships with a dedicated dashboard for developers under `/dev_tools`, designed exclusively to streamline and optimize local testing and user session spoofing capabilities for core developers. 

It is strictly restricted from being accessible or rendering in outside environments (`production` and `test` environments physically block routing entirely via Rails `routes.rb`), making its contents extremely safe for local operations without fear of credential leaks.

## Capabilities

### Instant Session Spoofing (`One-Click Sign-in`)
When testing interactions across permission roles, manually booting browsers in incognito tabs, maintaining passwords, and repeatedly typing in credential sets across multiple seeded accounts slows down test velocity significantly.

The `/dev_tools` environment lists the most recent `100` dynamically seeded Users locally, including an explicit array detailing the roles assigned natively and the organization relationships currently mapped against their user profile. You can click "Sign in natively" on any row to instantly override your browser's existing user session with theirs seamlessly. 

### Useful Scripts Repository
At the bottom of the dashboard, you will find documented executions mapped to standard utility scripts, such as `bin/fresh_start`. These explicitly outline what the scripts execute natively on the file system, helping onboard developers who are evaluating how database replants or test migrations evaluate artifacts sitting safely below the view logic.

## Booting
There is no setup necessary. From any standard local development boot context, browse directly onto:
`http://localhost:3000/dev_tools`

## Extension Recommendations
If you are extending `dev_tools`, ALWAYS wrap your implementation directly mapping against:
```ruby
  before_action :ensure_development_environment

  private

  def ensure_development_environment
    head :forbidden unless Rails.env.development?
  end
```
Never leak production or QA environments back downwards into local diagnostic layouts!

module DataUpdateScripts
  class CreateLivePage
    def run
      page = Page.find_or_create_by(slug: "live")

      body_html = <<-HEREDOC
      <link rel="canonical" href="https://dev.to/live" />
      <meta name="description" content="DEV LIVE">
      <meta name="keywords" content="software development,engineering,rails,javascript,ruby">

      <meta property="og:type" content="article" />
      <meta property="og:url" content="https://dev.to/live" />
      <meta property="og:title" content="DEV LIVE" />
      <meta property="og:image" content="https://thepracticaldev.s3.amazonaws.com/i/bqzj1pwho9e0jicqo44s.png" />
      <meta property="og:description" content="DEV Live Events" />
      <meta property="og:site_name" content="The Practical Dev" />

      <meta name="twitter:card" content="summary_large_image">
      <meta name="twitter:site" content="@ThePracticalDev">
      <meta name="twitter:title" content="DEV LIVE">
      <meta property="og:description" content="DEV Live Events" />
      <meta name="twitter:image:src" content="https://thepracticaldev.s3.amazonaws.com/i/bqzj1pwho9e0jicqo44s.png">

      <div class="live-upcoming-info">
        <h1>We are working on more ways to bring live coding to the community.</h1>
        <h2>Check out <a href="/settings/integrations">the integrations tab in your settings</a>.</h2>
      </div>
      HEREDOC
      page.update!(body_html: body_html, description: "DEV Live", title: "live", template: "full_within_layout", is_top_level_path: true)
    end
  end
end

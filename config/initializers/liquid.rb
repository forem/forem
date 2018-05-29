# registering all liquid tags

# dynamic
Liquid::Template.register_tag("devcomment", CommentTag)
Liquid::Template.register_tag("github", GithubTag)
Liquid::Template.register_tag("link", LinkTag)
Liquid::Template.register_tag("podcast", PodcastTag)
Liquid::Template.register_tag("tweet", TweetTag)
Liquid::Template.register_tag("twitter", TweetTag)
Liquid::Template.register_tag("user", UserTag)

# static
Liquid::Template.register_tag("codepen", CodepenTag)
Liquid::Template.register_tag("gist", GistTag)
Liquid::Template.register_tag("instagram", InstagramTag)
Liquid::Template.register_tag("speakerdeck", SpeakerdeckTag)
Liquid::Template.register_tag("glitch", GlitchTag)
Liquid::Template.register_tag("replit", ReplitTag)
Liquid::Template.register_tag("runkit", RunkitTag)
Liquid::Template.register_tag("youtube", YoutubeTag)
Liquid::Template.register_filter(UrlDecodeFilter)

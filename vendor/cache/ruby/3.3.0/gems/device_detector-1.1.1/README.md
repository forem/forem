# DeviceDetector

[![CI](https://github.com/podigee/device_detector/workflows/CI/badge.svg)](https://github.com/podigee/device_detector/actions)

DeviceDetector is a precise and fast user agent parser and device detector written in Ruby, backed by the largest and most up-to-date user agent database.

DeviceDetector will parse any user agent and detect the browser, operating system, device used (desktop, tablet, mobile, tv, cars, console, etc.), brand and model. DeviceDetector detects thousands of user agent strings, even from rare and obscure browsers and devices.

The DeviceDetector is optimized for speed of detection, by providing optimized code and in-memory caching.

This project originated as a Ruby port of the Universal Device Detection library.
You can find the original code here: https://github.com/piwik/device-detector.

## Disclaimer

This port does not aspire to be a one-to-one copy from the original code, but rather an adaptation for the Ruby language.

Still, our goal is to use the original, unchanged regex yaml files, in order to mutually benefit from updates and pull request to both the original and the ported versions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'device_detector'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install device_detector

## Usage

```ruby
user_agent = 'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.17 Safari/537.36'
client = DeviceDetector.new(user_agent)

client.name # => 'Chrome'
client.full_version # => '30.0.1599.69'

client.os_name # => 'Windows'
client.os_full_version # => '8'

# For many devices, you can also query the device name (usually the model name)
client.device_name # => 'iPhone 5'
# Device types can be one of the following: desktop, smartphone, tablet,
# feature phone, console, tv, car browser, smart display, camera,
# portable media player, phablet, smart speaker, wearable, peripheral
client.device_type # => 'smartphone'
```

`DeviceDetector` will return `nil` on all attributes, if the `user_agent` is unknown.
You can make a check to ensure the client has been detected:

```ruby
client.known? # => will return false if user_agent is unknown
```
### Using Client hint

Optionally `DeviceDetector` is using the content of `Sec-CH-UA` stored in the headers to improve the accuracy of the detection :

```ruby
user_agent = 'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.17 Safari/537.36'
headers = {"Sec-CH-UA"=>'"Chromium";v="106", "Brave";v="106", "Not;A=Brand";v="99"'}
client = DeviceDetector.new(user_agent, headers)

client.name # => 'Brave'
```

Same goes with `http-x-requested-with`/`x-requested-with` :

``` ruby
user_agent = 'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.17 Safari/537.36'
headers = {"http-x-requested-with"=>"org.mozilla.focus"}
client = DeviceDetector.new(user_agent, headers)

client.name # => 'Firefox Focus'
```

### Memory cache

`DeviceDetector` will cache up 5,000 user agent strings to boost parsing performance.
You can tune the amount of keys that will get saved in the cache. You have to call this code **before** you initialize the Detector.

```ruby
DeviceDetector.configure do |config|
  config.max_cache_keys = 5_000 # increment this if you have enough RAM, proceed with care
end
```

If you have a Rails application, you can create an initializer, for example `config/initializers/device_detector.rb`.

## Benchmarks

We have measured the parsing speed of almost 200,000 non-unique user agent strings and compared the speed of DeviceDetector with the two most popular user agent parsers in the Ruby community, Browser and UserAgent.

### Testing machine specs

- MacBook Pro 15", Late 2013
- 2.6 GHz Intel Core i7
- 16 GB 1600 MHz DDR3

### Gem versions

- DeviceDetector - 0.5.1
- Browser - 0.8.0
- UserAgent - 0.13.1

### Code

```ruby
require 'device_detector'
require 'browser'
require 'user_agent'
require 'benchmark'

user_agent_strings = File.read('./tmp/user_agent_strings.txt').split("\n")

## Benchmarks

Benchmark.bm(15) do |x|
  x.report('device_detector') {
    user_agent_strings.each { |uas| DeviceDetector.new(uas).name }
  }
  x.report('browser') {
    user_agent_strings.each { |uas| Browser.new(ua: uas).name }
  }
  x.report('useragent') {
    user_agent_strings.each { |uas| UserAgent.parse(uas).browser }
  }
end
```

### Results

```
                      user     system      total        real
device_detector   1.180000   0.010000   1.190000 (  1.198721)
browser           2.240000   0.010000   2.250000 (  2.245493)
useragent         4.490000   0.020000   4.510000 (  4.500673)

                      user     system      total        real
device_detector   1.190000   0.020000   1.210000 (  1.201447)
browser           2.250000   0.010000   2.260000 (  2.261001)
useragent         4.440000   0.010000   4.450000 (  4.451693)

                      user     system      total        real
device_detector   1.210000   0.020000   1.230000 (  1.228617)
browser           2.220000   0.010000   2.230000 (  2.222565)
useragent         4.450000   0.000000   4.450000 (  4.452741)
```

## Detectable clients, bots and devices

Updated on 2023-08-01

### Bots

2ip, 360 Monitoring, 360Spider, Abonti, Aboundexbot, Acoon, AdAuth, Adbeat, AddThis.com, ADMantX, ADmantX Service Fetcher, Adsbot, AdsTxtCrawler, adstxtlab.com, aHrefs Bot, AhrefsSiteAudit, aiHitBot, Alexa Crawler, Alexa Site Audit, Allloadin Favicon Bot, Amazon Bot, Amazon ELB, Amazon Route53 Health Check, Amorank Spider, Analytics SEO Crawler, ApacheBench, Applebot, AppSignalBot, Arachni, archive.org bot, ArchiveBox, Asana, Ask Jeeves, AspiegelBot, Awario, Backlink-Check.de, BacklinkCrawler, Baidu Spider, Barkrowler, BazQux Reader, BDCbot, Better Uptime Bot, BingBot, Birdcrawlerbot, BitlyBot, BitSight, Blekkobot, BLEXBot Crawler, Bloglovin, Blogtrottr, BoardReader, BoardReader Blog Indexer, Bountii Bot, BrandVerity, BrightEdge, Browsershots, BUbiNG, Buck, BuiltWith, Butterfly Robot, Bytespider, CareerBot, Castro 2, Catchpoint, CATExplorador, ccBot crawler, CensysInspect, Charlotte, ChatGPT, Choosito, Chrome Privacy Preserving Prefetch Proxy, Cincraw, CISPA Web Analyzer, Cliqzbot, CloudFlare Always Online, CloudFlare AMP Fetcher, Cloudflare Diagnostics, Cloudflare Health Checks, Cocolyzebot, Collectd, colly, CommaFeed, COMODO DCV, Comscore, ContentKing, Cookiebot, Crawldad, Crawlson, CriteoBot, CrowdTangle, CSS Certificate Spider, Cyberscan, Cốc Cốc Bot, Datadog Agent, DataForSeoBot, datagnionbot, Datanyze, Dataprovider, DataXu, Daum, Dazoobot, deepnoc, Diffbot, Discobot, Discord Bot, Disqus, DNSResearchBot, Domain Re-Animator Bot, DomainAppender, DomainCrawler, Domains Project, DomainStatsBot, DotBot, Dotcom Monitor, DuckDuckGo Bot, Easou Spider, eCairn-Grabber, EFF Do Not Track Verifier, EMail Exractor, EmailWolf, Embedly, Entfer, evc-batch, Everyfeed, ExaBot, ExactSeek Crawler, Exchange check, Expanse, eZ Publish Link Validator, Ezgif, Ezooms, Facebook External Hit, Faveeo, Feed Wrangler, Feedbin, FeedBurner, Feedly, Feedspot, Femtosearch, Fever, Findxbot, Flipboard, FreeWebMonitoring, FreshRSS, GDNP, Generic Bot, Genieo Web filter, Gigablast, Gigabot, GitCrawlerBot, Gluten Free Crawler, Gmail Image Proxy, Gobuster, Goo, Google Cloud Scheduler, Google Favicon, Google PageSpeed Insights, Google Partner Monitoring, Google Search Console, Google Stackdriver Monitoring, Google StoreBot, Google Structured Data Testing Tool, Googlebot, Gowikibot, Grammarly, Grapeshot, Gregarius, GTmetrix, GumGum Verity, hackermention, Hatena Bookmark, Hatena Favicon, Headline, Heart Rails Capture, Heritrix, Heureka Feed, HTTPMon, httpx, HuaweiWebCatBot, HubPages, HubSpot, ICC-Crawler, ichiro, IDG/IT, Iframely, IIS Site Analysis, Inetdex Bot, Infegy, InfoTigerBot, Inktomi Slurp, inoreader, Intelligence X, InternetMeasurement, IONOS Crawler, IP-Guide Crawler, IPIP, IPS Agent, JobboerseBot, JungleKeyThumbnail, K6, Kaspersky, KlarnaBot, KomodiaBot, Kouio, Kozmonavt, l9explore, l9tcpid, Larbin web crawler, LastMod Bot, LCC, LeakIX, Let's Encrypt Validation, Lighthouse, Linespider, Linkdex Bot, LinkedIn Bot, LinkpadBot, LinkPreview, LinkWalker, LTX71, Lumar, LumtelBot, Lycos, MaCoCu, Magpie-Crawler, MagpieRSS, Mail.Ru Bot, masscan, masscan-ng, Mastodon Bot, Meanpath Bot, Mediatoolkit Bot, MegaIndex, MetaInspector, MetaJobBot, MicroAdBot, Mixrank Bot, MJ12 Bot, Mnogosearch, MojeekBot, Monitor.Us, MoodleBot Linkchecker, Morningscore Bot, MTRobot, Munin, MuscatFerret, Nagios check_http, NalezenCzBot, nbertaupete95, Neevabot, Netcraft Survey Bot, netEstate, NetLyzer FastProbe, NetResearchServer, NetSystemsResearch, Netvibes, NETZZAPPEN, NewsBlur, NewsGator, Newslitbot, NiceCrawler, Nimbostratus Bot, NLCrawler, Nmap, Notify Ninja, Nutch-based Bot, Nuzzel, oBot, Octopus, Odnoklassniki Bot, Omgili bot, Onalytica, OnlineOrNot Bot, Openindex Spider, OpenLinkProfiler, OpenWebSpider, Orange Bot, Outbrain, Overcast Podcast Sync, Page Modified Pinger, Pageburst, PagePeeker, PageThing, Panscient, PaperLiBot, parse.ly, PATHspider, PayPal IPN, PDR Labs, Petal Bot, Phantomas, PHP Server Monitor, Picsearch bot, PingAdmin.Ru, Pingdom Bot, Pinterest, PiplBot, Plukkie, Pocket, Pompos, PritTorrent, Project Patchwatch, Project Resonance, PRTG Network Monitor, QuerySeekerSpider, Quora Bot, Quora Link Preview, Qwantify, Rainmeter, RamblerMail Image Proxy, Reddit Bot, RenovateBot, Repo Lookout, ReqBin, Riddler, Robozilla, RocketMonitorBot, Rogerbot, ROI Hunter, RSSRadio Bot, Ryowl, SabsimBot, SafeDNSBot, Scamadviser External Hit, Scooter, ScoutJet, Scrapy, Screaming Frog SEO Spider, ScreenerBot, Sectigo DCV, security.txt scanserver, Seekport, Sellers.Guide, Semantic Scholar Bot, Semrush Bot, SEMrush Reputation Management, Sensika Bot, Sentry Bot, Seobility, SEOENGBot, SEOkicks, SEOkicks-Robot, seolyt, Seolyt Bot, Seoscanners.net, Serendeputy Bot, serpstatbot, Server Density, Seznam Bot, Seznam Email Proxy, Seznam Zbozi.cz, sfFeedReader, ShopAlike, Shopify Partner, ShopWiki, SilverReader, SimplePie, SISTRIX Crawler, SISTRIX Optimizer, Site24x7 Website Monitoring, Siteimprove, SitemapParser-VIPnytt, SiteSucker, Sixy.ch, Skype URI Preview, Slackbot, SMTBot, Snap URL Preview Service, Snapchat Proxy, Sogou Spider, Soso Spider, Sparkler, Speedy, Spinn3r, Spotify, Sprinklr, Sputnik Bot, Sputnik Favicon Bot, Sputnik Image Bot, sqlmap, SSL Labs, start.me, Startpagina Linkchecker, StatusCake, Sublinq, Superfeedr Bot, SurdotlyBot, Survey Bot, t3versions, Taboolabot, Tag Inspector, Tarmot Gezgin, tchelebi, TelegramBot, TestCrawler, The Knowledge AI, theoldreader, ThinkChaos, TigerBot, TinEye Crawler, Tiny Tiny RSS, TLSProbe, TraceMyFile, Trendiction Bot, Turnitin, TurnitinBot, TweetedTimes Bot, Tweetmeme Bot, Twingly Recon, Twitterbot, UkrNet Mail Proxy, uMBot, UniversalFeedParser, Uptime Robot, Uptime-Kuma, Uptimebot, URLAppendBot, URLinspector, Vagabondo, Velen Public Web Crawler, Vercel Bot, VeryHip, Visual Site Mapper Crawler, VK Share Button, Vuhuv Bot, W3C CSS Validator, W3C I18N Checker, W3C Link Checker, W3C Markup Validation Service, W3C MobileOK Checker, W3C Unified Validator, Wappalyzer, WebbCrawler, WebDataStats, Weborama, WebPageTest, WebPros, WebSitePulse, WebThumbnail, WellKnownBot, WeSEE:Search, WeViKaBot, WhatCMS, WhereGoes, WikiDo, Willow Internet Crawler, WooRank, WordPress, Wotbox, XenForo, XoviBot, YaCy, Yahoo Gemini, Yahoo! Cache System, Yahoo! Japan BRW, Yahoo! Link Preview, Yahoo! Mail Proxy, Yahoo! Slurp, YaK, Yandex Bot, Yeti/Naverbot, Yottaa Site Monitor, Youdao Bot, Yourls, Yunyun Bot, Zaldamo, Zao, Ze List, zgrab, Zookabot, ZoominfoBot, ZumBot

### Clients

115 Browser, 1Password, 2345 Browser, 2tch, 360 Browser, 360 Phone Browser, 7654 Browser, 7Star, ABrowse, AdBlock Browser, Adobe Creative Cloud, Adobe IPM, Adobe NGL, Adobe Synchronizer, Aha Radio 2, AIDA64, aiohttp, Airmail, Akka HTTP, Akregator, Alexa Media Player, AliExpress, Alipay, Aloha Browser, Aloha Browser Lite, Amaya, Amazon Music, Amazon Shopping, Amiga Aweb, Amiga Voyager, Amigo, Android Browser, AndroidDownloadManager, ANT Fresco, AntennaPod, ANTGalio, AntiBrowserSpy, AnyEvent HTTP, AOL Desktop, AOL Shield, AOL Shield Pro, Apache HTTP Client, APN Browser, Apple News, Apple PubSub, Apple TV, Arctic Fox, Aria2, Arora, Artifactory, Arvin, ASUS Updater, Atom, Atomic Web Browser, Audacious, Audible, Avant Browser, Avast Secure Browser, AVG Secure Browser, Avid Link, Avira Scout, AwoX, Axios, Azure Data Factory, B-Line, Background Intelligent Transfer Service, Baidu Box App, Baidu Browser, Baidu Input, Baidu Spark, Ballz, Bangla Browser, Bank Millenium, Banshee, Barca, Basecamp, BashPodder, Basilisk, BathyScaphe, Battle.net, BB2C, BBC News, Be Focused, Beaker Browser, Beamrise, Beonex, BetBull, BeyondPod, Bible KJV, Binance, Bing iPad, BingWebApp, Bitcoin Core, Bitsboard, Biyubi, BlackBerry Browser, Blackboard, BlackHawk, Blitz, Bloket, Blue Browser, Blue Proxy, BlueStacks, BonPrix, Bonsai, Bookshelf, Borealis Navigator, Bose Music, Boxee, bPod, Brave, Breaker, BriskBard, Browlser, BrowseHere, BrowseX, Browzar, Buildah, BuildKit, Bunjalloo, Byffox, C++ REST SDK, Camino, CastBox, Castro, Castro 2, CCleaner, Centaury, CGN, ChanjetCloud, Charon, Chedot, Cheetah Browser, Cheshire, Chim Lac, ChMate, Chrome, Chrome Frame, Chrome Mobile, Chrome Mobile iOS, Chrome Update, Chrome Webview, ChromePlus, Chromium, Chromium GOST, Ciisaa, Citrix Workspace, Clementine, Clovia, CM Browser, COAF SMART Citizen, Coast, Coc Coc, Colibri, CometBird, Comodo Dragon, Conkeror, Containerd, containers, CoolBrowser, CoolNovo, Copied, Cornowser, Cortana, COS Browser, Covenant Eyes, cPanel HTTP Client, CPU-Z, Craving Explorer, Crazy Browser, cri-o, CrosswalkApp, Crusta, Cunaguaro, curl, Cyberfox, CyBrowser, Dart, Daum, DAVdroid, dbrowser, Decentr, Deepnet Explorer, Deezer, deg-degan, Deledao, Delta Browser, DeskBrowse, DevCasts, DeviantArt, Dillo, DingTalk, DIRECTV, Discord, docker, DoggCatcher, Dolphin, Don't Waste My Time!, Dooble, Dorado, Dot Browser, douban App, Downcast, Dr. Watson, DStream Air, DuckDuckGo Privacy Browser, Ecosia, Edge Update, Edge WebView, Element Browser, Elements Browser, Elinks, eM Client, Embarcadero URI Client, Emby Theater, Epic, Epic Games Launcher, ESET Remote Administrator, Espial TV Browser, eToro, EUI Browser, Evernote, Evolve Podcast, Expedia, eZ Browser, F-Secure SAFE, Facebook, Facebook Audience Network, Facebook Groups, Facebook Lite, Facebook Messenger, Facebook Messenger Lite, Falkon, Faraday, fasthttp, Faux Browser, FeedDemon, Feeddler RSS Reader, FeedR, Fennec, Firebird, Firefox, Firefox Focus, Firefox Mobile, Firefox Mobile iOS, Firefox Reality, Firefox Rocket, Fireweb, Fireweb Navigator, Flash Browser, Flast, Flipboard App, Flipp, Flock, Floorp, Flow, Flow Browser, Fluid, FlyCast, Focus Keeper, Focus Matrix, Foobar2000, foobar2000, Franz, FreeU, Gaana, Galeon, GBWhatsApp, GeoIP Update, Ghostery Privacy Browser, GinxDroid Browser, Git, GitHub Desktop, Glass Browser, GlobalProtect, GNOME Web, go-container registry, Go-http-client, GoBrowser, GOG Galaxy, GoNative, Google Drive, Google Earth, Google Earth Pro, Google Fiber TV, Google Go, Google HTTP Java Client, Google Photos, Google Play Newsstand, Google Plus, Google Podcasts, Google Search App, Google Tag Manager, got, gPodder, GRequests, GroupMe, gRPC-Java, Guzzle (PHP HTTP Client), gvfs, hackney, Hago, HandBrake, Harbor registry client, Harman Browser, HasBrowser, Hawk Quick Browser, Hawk Turbo Browser, Headless Chrome, Helio, Helm, HeyTapBrowser, Hi Browser, Hik-Connect, HiSearch, HisThumbnail, hola! Browser, HotJava, HP Smart, HTC Streaming Player, HTTP request maker, HTTP_Request2, HTTPie, httplib2, HTTPX, Huawei Browser, Huawei Browser Mobile, IBrowse, iBrowser, iBrowser Mini, iCab, iCab Mobile, iCatcher, IceCat, IceDragon, Iceweasel, IE Mobile, IMO HD Video Calls & Chat, IMO International Calls & Chat, Insomnia REST Client, Inspect Browser, Instabridge, Instacast, Instagram App, Instapaper, Internet Explorer, Iridium, Iron, Iron Mobile, Isivioo, iTunes, Jakarta Commons HttpClient, JaneStyle, JaneView, Japan Browser, Jasmine, Java, Java HTTP Client, JavaFX, JetBrains Omea Reader, Jig Browser, Jig Browser Plus, Jio Browser, Jitsi Meet, JJ2GO, jsdom, Jungle Disk, K-meleon, K.Browser, KakaoTalk, Kapiko, Kazehakase, Keeper Password Manager, Keepsafe Browser, Kik, Kindle Browser, Kinza, Kiwi, Klarna, Kode Browser, Kodi, Konqueror, Kylo, Lagatos Browser, Landis+Gyr AIM Browser, Lazada, Lenovo Browser, Lexi Browser, LG Browser, libdnf, libpod, LieBaoFast, Liferea, Light, Lilo, Line, LinkedIn, Links, Live5ch, Logi Options+, Lolifox, LoseIt!, Lotus Notes, Lovense Browser, LT Browser, LUA OpenResty NGINX, LuaKit, Lulumi, Lunascape, Lunascape Lite, Lynx, Macrium Reflect, Maelstrom, MailBar, Mailbird, Mailspring, Mandarin, MAUI WAP Browser, Maxthon, MBolsa, mCent, Mechanize, MediaMonkey, Meizu Browser, MEmpresas, Mercantile Bank of Michigan, Mercury, Meta Business Suite, MetaTrader, MicroB, Microsoft Bing Search, Microsoft Edge, Microsoft Lync, Microsoft Office, Microsoft Office $1, Microsoft Office Mobile, Microsoft OneDrive, Microsoft Outlook, Microsoft Start, Microsoft Store, Midori, Mikrotik Fetch, Minimo, Mint Browser, Miro, MIUI Browser, Mobicip, Mobile Safari, Mobile Silk, mobile.de, Monument Browser, MPlayer, mpv, Music Player Daemon, MxNitro, My Bentley, My Watch Party, My World, Mypal, Naver, NAVER Mail, Navigateur Web, NCSA Mosaic, NET.mede, Netflix, NetFront, NetFront Life, NetNewsWire, NetPositive, Netscape, NetSurf, NewsArticle App, Newsbeuter, NewsBlur, NewsBlur Mobile App, NexPlayer, Nextcloud, NFS Browser, Nightingale, Node Fetch, Nokia Browser, Nokia OSS Browser, Nokia Ovi Browser, Notion, Nox Browser, NPR One, NTENT Browser, NTV Mobil, NuMuKi Browser, Obigo, OceanHero, Oculus Browser, Odin, Odnoklassniki, Odyssey Web Browser, Off By One, OfferUp, OhHai Browser, OkHttp, OmniWeb, ONE Browser, Opal Travel, Open Build Service, OpenFin, Openwave Mobile Browser, Opera, Opera Devices, Opera GX, Opera Mini, Opera Mini iOS, Opera Mobile, Opera Neon, Opera News, Opera Next, Opera Touch, Opera Updater, Oppo Browser, Orange Radio, Orca, Ordissimo, Oregano, Origin In-Game Overlay, Origyn Web Browser, Otter Browser, Outlook Express, Overcast, Pa11y, Paint by Number, Pale Moon, Palm Blazer, Palm Pre, Palm WebPro, Palmscape, Pandora, Papers, Peeps dBrowser, Perfect Browser, Perl, Perl REST::Client, Petal Search App, Phantom Browser, Phoenix, Phoenix Browser, PHP cURL Class, Pi Browser, Pic Collage, Pinterest, Player FM, PlayFree Browser, Plex Media Server, Pocket Casts, PocketBook Browser, Podbean, Podcast & Radio Addict, Podcast Republic, Podcaster, Podcasts, Podcat, Podcatcher Deluxe, Podimo, Podkicker$1, Polaris, Polarity, PolyBrowser, Polypane, Postbox, Postman Desktop, PowerShell, PritTorrent, PrivacyWall, Procast, PSI Secure Browser, Puffin, Pulp, Python Requests, Python urllib, Q-municate, Qazweb, qBittorrent, QQ Browser, QQ Browser Lite, QQ Browser Mini, QQMusic, QtWebEngine, Quark, quic-go, Quick Search TV, QuickCast, QuickTime, QuiteRSS, Quora, QupZilla, Qutebrowser, Qwant Mobile, R, r-curl, Radio Italiane, RadioApp, RadioPublic, Raindrop.io, Rambox Pro, Rave Social, Razer Synapse, RDDocuments, ReactorNetty, ReadKit, Realme Browser, Reddit, Reeder, Rekonq, rekordbox, req, Reqwireless WebViewer, REST Client for Ruby, RestSharp, Resty, RNPS Action Cards, Roblox, RoboForm, Rocket Chat, RockMelt, RSS Bandit, RSS Junkie, RSSOwl, RSSRadio, Rutube, Safari, Safari Search Helper, Safari Technology Preview, Safe Exam Browser, SafeIP, Sailfish Browser, SalamWeb, Samsung Browser, Samsung Magician, ScalaJ HTTP, SeaMonkey, Secure Browser, Secure Private Browser, Seewo Browser, SEMC-Browser, Seraphic Sraf, Seznam Browser, SFive, Shiira, Shopee, ShowMe, SimpleBrowser, Sina Weibo, Siri, SiteKiosk, Sizzy, Skopeo, Skyeng, Skyeng Teachers, Skyfire, Skype, Skype for Business, Slack, Sleipnir, SlimerJS, Slimjet, Smart Lenovo Browser, Smooz, Snapchat, Snowshoe, Sogou Explorer, Sogou Mobile Browser, SogouSearch App, SohuNews, Soldier, Songbird, SONOS, Sony Media Go, Soul Browser, SP Browser, Spectre Browser, Splash, SPORT1, Spotify, Sputnik Browser, Stagefright, Stampy Browser, Stargon, START Internet Browser, Startsiden, Steam In-Game Overlay, Streamlabs OBS, Streamy, Strimio, Stringer, SubStream, Sunrise, Super Fast Browser, SuperBird, surf, Surf Browser, Surfshark, Sushi Browser, Swiftfox, Swoot, T+Browser, T-Browser, t-online.de Browser, Tao Browser, Taobao, Teams, TenFourFox, Tenta Browser, Tesla Browser, The Bat!, The Wall Street Journal, Theyub, Thunder, Thunderbird, tieba, TikTok, Tizen Browser, ToGate, TopBuzz, TradingView, TuneIn Radio, TuneIn Radio Pro, Tungsten, Tuya Smart Life, TV Bro, TVirl, TweakStyle, twinkle, Twitter, Twitterrific, Typhoeus, U Browser, U-Cursos, UBrowser, UC Browser, UC Browser HD, UC Browser Mini, UC Browser Turbo, uclient-fetch, Uconnect LIVE, Ultimate Sitemap Parser, Unibox, Unirest for Java, UnityPlayer, UR Browser, urlgrabber (yum), uTorrent, Uzbl, Vast Browser, Venus Browser, Viasat Browser, Viber, Vision Mobile Browser, Visual Studio Code, Vivaldi, vivo Browser, VLC, VMware AirWatch, Vuhuv, Vuze, Waterfox, Wattpad, Wayback Machine, Wear Internet Browser, Web Explorer, WebDAV, WebPositive, WeChat, WeChat Share Extension, WeTab Browser, Wget, WH Questions, Whale Browser, WhatsApp, WhatsApp+2, Whisper, Winamp, Windows Antivirus, Windows CryptoAPI, Windows Delivery Optimization, Windows HTTP, Windows Mail, Windows Media Player, Windows Push Notification Services, Windows Update Agent, WinHttp WinHttpRequest, Wireshark, Wirtschafts Woche, Wolvic, Word Cookies!, wOSBrowser, WPS Office, WWW-Mechanize, XBMC, Xiino, xStand, Xvast, Y8 Browser, Yaani Browser, YAGI, Yahoo Mail, Yahoo OneSearch, Yahoo! Japan, Yahoo! Japan Browser, YakYak, Yandex, Yandex Browser, Yandex Browser Lite, Yelp Mobile, Yolo Browser, YouCare, YouTube, Zalo, ZEPETO, Zetakey, Zoho Chat, Zvu

### Devices

10moons, 2E, 360, 3GNET, 3GO, 3Q, 4Good, 4ife, 5IVE, 7 Mobile, 8848, A1, A95X, Accent, Accesstyle, Ace, Acer, Acteck, actiMirror, Adronix, Advan, Advance, Advantage Air, AEEZO, AFFIX, AfriOne, AG Mobile, AGM, AIDATA, Ainol, Airis, Airness, AIRON, Airpha, Airtel, Airties, AIS, Aiuto, Aiwa, Akai, AKIRA, Alba, Alcatel, Alcor, ALDI NORD, ALDI SÜD, Alfawise, Aligator, AllCall, AllDocube, ALLINmobile, Allview, Allwinner, Alps, Altech UEC, Altice, altron, AMA, Amazon, AMCV, AMGOO, Amigoo, Amino, Amoi, Andowl, Angelcare, Anker, Anry, ANS, ANXONIT, AOC, Aocos, AOpen, Aoro, Aoson, AOYODKG, Apple, Aquarius, Archos, Arian Space, Ark, ArmPhone, Arnova, ARRIS, Artel, Artizlee, ArtLine, Asano, Asanzo, Ask, Aspera, ASSE, Assistant, Astro, Asus, AT&T, Athesi, Atmaca Elektronik, ATMAN, ATOL, Atom, Attila, Atvio, Audiovox, AURIS, Autan, AUX, Avaya, Avenzo, AVH, Avvio, Awow, Axioo, AXXA, Axxion, AYYA, Azumi Mobile, b2m, Backcell, BAFF, BangOlufsen, Barnes & Noble, BARTEC, BB Mobile, BBK, BDF, BDQ, BDsharing, Beafon, Becker, Beeline, Beelink, Beetel, Beista, Bellphone, Benco, Benesse, BenQ, BenQ-Siemens, BenWee, Benzo, Beyond, Bezkam, BGH, Bigben, BIHEE, BilimLand, Billion, Billow, BioRugged, Bird, Bitel, Bitmore, Bittium, Bkav, Black Bear, Black Fox, Blackpcs, Blackview, Blaupunkt, Bleck, BLISS, Blloc, Blow, Blu, Bluboo, Bluebird, Bluedot, Bluegood, BlueSky, Bluewave, BluSlate, BMAX, Bmobile, BMXC, Bobarry, bogo, Bolva, Bookeen, Boost, Boway, bq, BrandCode, Brandt, BRAVE, Bravis, BrightSign, Brigmton, Brondi, BROR, BS Mobile, Bubblegum, Bundy, Bush, BuzzTV, C5 Mobile, CAGI, Camfone, Canal Digital, Canguro, Capitel, Captiva, Carbon Mobile, Carrefour, Casio, Casper, Cat, Cavion, Ceibal, Celcus, Celkon, Cell-C, Cellacom, CellAllure, Cellution, Centric, CG Mobile, CGV, Chainway, Changhong, Cherry Mobile, Chico Mobile, ChiliGreen, China Mobile, China Telecom, Chuwi, CipherLab, Citycall, Claresta, Clarmin, ClearPHONE, Clementoni, Cloud, Cloudfone, Cloudpad, Clout, CnM, Cobalt, Coby Kyros, Colors, Comio, Compal, Compaq, COMPUMAX, ComTrade Tesla, Conceptum, Concord, ConCorde, Condor, Connectce, Connex, Conquest, Contixo, Coolpad, Coopers, CORN, Cosmote, Covia, Cowon, COYOTE, CreNova, Crescent, Cricket, Crius Mea, Crony, Crosscall, Crown, Ctroniq, Cube, CUBOT, CVTE, Cwowdefu, Cyrus, D-Link, D-Tech, Daewoo, Danew, DangcapHD, Dany, DASS, Datalogic, Datamini, Datang, Datawind, Datsun, Dazen, DbPhone, Dbtel, Dcode, DEALDIG, Dell, Denali, Denver, Desay, DeWalt, DEXP, DEYI, DF, DGTEC, Dialog, Dicam, Digi, Digicel, DIGICOM, Digidragon, DIGIFORS, Digihome, Digiland, Digit4G, Digma, DIJITSU, DIMO, Dinax, DING DING, DISH, Disney, Ditecma, Diva, DiverMax, Divisat, DIXON, DL, DMM, DNS, DoCoMo, Doffler, Dolamee, Dom.ru, Doogee, Doopro, Doov, Dopod, Doppio, DORLAND, Doro, DPA, DRAGON, Dragon Touch, Dreamgate, DreamStar, DreamTab, Droxio, DSIC, Dtac, Dune HD, DUNNS Mobile, Durabook, Duubee, E-Boda, E-Ceros, E-tel, Eagle, Easypix, EBEN, EBEST, Echo Mobiles, ecom, ECON, ECOO, ECS, EE, EFT, EGL, Einstein, EKINOX, EKO, Eks Mobility, EKT, ELARI, Elecson, Electroneum, ELECTRONIA, Elekta, Element, Elenberg, Elephone, Elevate, Elong Mobile, Eltex, Ematic, Emporia, ENACOM, Energizer, Energy Sistem, Engel, ENIE, Enot, eNOVA, Entity, Envizen, Ephone, Epic, Epik One, Epson, Equator, Ergo, Ericsson, Ericy, Erisson, Essential, Essentielb, eSTAR, Eton, eTouch, Etuline, Eurocase, Eurostar, Evercoss, Everest, Everex, Evertek, Evolio, Evolveo, Evoo, EVPAD, EvroMedia, EWIS, EXCEED, Exmart, ExMobile, EXO, Explay, Extrem, EYU, Ezio, Ezze, F&U, F+, F150, F2 Mobile, Facebook, Facetel, Facime, Fairphone, Famoco, Famous, Fantec, FaRao Pro, Farassoo, FarEasTone, Fengxiang, FEONAL, Fero, FFF SmartLife, Figgers, FiGi, FiGO, FiiO, FILIX, FinePower, Finlux, FireFly Mobile, FISE, Fluo, Fly, FLYCAT, FMT, FNB, FNF, Fondi, Fonos, FOODO, FORME, Formuler, Forstar, Fortis, FOSSiBOT, Four Mobile, Fourel, Foxconn, FoxxD, FPT, Freetel, Frunsi, Fuego, Fujitsu, Funai, Fusion5, Future Mobile Technology, Fxtec, G-TiDE, G-Touch, Galactic, Galaxy Innovations, Gamma, Garmin-Asus, Gateway, Gazer, Geanee, Geant, Gear Mobile, Gemini, General Mobile, Genesis, GEOFOX, Geotel, Geotex, GEOZON, GFive, Gfone, Ghia, Ghong, Ghost, Gigabyte, Gigaset, Gini, Ginzzu, Gionee, GIRASOLE, Globex, Glofiish, GLONYX, GLX, GOCLEVER, Gocomma, GoGEN, Gol Mobile, GoldMaster, Goly, Gome, GoMobile, GOODTEL, Google, Goophone, Gooweel, Gplus, Gradiente, Grape, Great Asia, Gree, Green Orange, Greentel, Gresso, Gretel, GroBerwert, Grundig, Gtel, GTMEDIA, Guophone, H133, H96, Hafury, Haier, Haipai, Hamlet, Hammer, Handheld, HannSpree, HAOQIN, HAOVM, Hardkernel, Harper, Hartens, Hasee, Hathway, HDC, HeadWolf, Helio, HERO, HexaByte, Hezire, Hi, Hi Nova, Hi-Level, Hiberg, High Q, Highscreen, HiHi, HiKing, HiMax, HIPER, Hipstreet, Hisense, Hitachi, Hitech, HKPro, HLLO, Hoffmann, Hometech, Homtom, Honeywell, Hoozo, Horizon, Horizont, Hosin, Hot Pepper, Hotel, HOTREALS, Hotwav, How, HP, HTC, Huadoo, Huagan, Huavi, Huawei, Hugerock, Humax, Hurricane, Huskee, Hykker, Hytera, Hyundai, Hyve, i-Cherry, I-INN, i-Joy, i-mate, i-mobile, iBall, iBerry, ibowin, iBrit, IconBIT, iData, iDino, iDroid, iGet, iHunt, Ikea, IKI Mobile, iKoMo, iKon, IKU Mobile, iLA, iLepo, iLife, iMan, iMars, iMI, IMO Mobile, Imose, Impression, iMuz, iNavi, INCAR, Inch, Inco, iNew, Infiniton, Infinix, InFocus, InfoKit, InFone, Inhon, Inkti, InnJoo, Innos, Innostream, iNo Mobile, Inoi, iNOVA, INQ, Insignia, INSYS, Intek, Intel, Intex, Invens, Inverto, Invin, iOcean, iOutdoor, iPEGTOP, iPro, iQ&T, IQM, IRA, Irbis, iReplace, Iris, iRobot, iRola, iRulu, iSafe Mobile, iStar, iSWAG, IT, iTel, iTruck, IUNI, iVA, iView, iVooMi, ivvi, iWaylink, iXTech, iYou, iZotron, JAY-Tech, Jedi, Jeka, Jesy, JFone, Jiake, Jiayu, Jinga, Jio, Jivi, JKL, Jolla, Joy, JoySurf, JPay, JREN, Jumper, Juniper Systems, Just5, JVC, JXD, K-Lite, K-Touch, Kaan, Kaiomy, Kalley, Kanji, Kapsys, Karbonn, Kata, KATV1, Kazam, Kazuna, KDDI, Kempler & Strauss, Kenbo, Keneksi, Kenxinda, Khadas, Kiano, Kingbox, Kingstar, Kingsun, KINGZONE, Kinstone, Kiowa, Kivi, Klipad, KN Mobile, Kocaso, Kodak, Kogan, Komu, Konka, Konrow, Koobee, Koolnee, Kooper, KOPO, Koridy, Koslam, Kraft, KREZ, KRIP, KRONO, Krüger&Matz, KT-Tech, KUBO, KuGou, Kuliao, Kult, Kumai, Kurio, Kvant, Kyocera, Kyowon, Kzen, KZG, L-Max, LAIQ, Land Rover, Landvo, Lanin, Lanix, Lark, Laurus, Lava, LCT, Le Pan, Leader Phone, Leagoo, Leben, LeBest, Lectrus, Ledstar, LeEco, Leelbox, Leff, Legend, Leke, LEMFO, Lemhoov, Lenco, Lenovo, Leotec, Lephone, Lesia, Lexand, Lexibook, LG, Liberton, Lifemaxx, Lime, Lingwin, Linnex, Linsar, Linsay, Listo, LNMBBS, Loewe, Logic, Logic Instrument, Logicom, LOKMAT, Loview, Lovme, LPX-G, LT Mobile, Lumigon, Lumitel, Lumus, Luna, Luxor, LYF, M-Horse, M-Tech, M.T.T., M3 Mobile, M4tel, MAC AUDIO, Macoox, Mafe, Magicsee, Magnus, Majestic, Malata, Mango, Manhattan, Mann, Manta Multimedia, Mantra, Mara, Marshal, Mascom, Massgo, Masstel, Master-G, Mastertech, Matrix, Maxcom, Maxfone, Maximus, Maxtron, MAXVI, Maxwest, MAXX, Maze, Maze Speed, MBI, MBOX, MDC Store, MDTV, meanIT, Mecer, Mecool, Mediacom, MediaTek, Medion, MEEG, MegaFon, Meitu, Meizu, Melrose, Memup, Meta, Metz, MEU, MicroMax, Microsoft, Microtech, Minix, Mint, Mintt, Mio, Mione, Miray, Mito, Mitsubishi, Mitsui, MIVO, MIWANG, MIXC, MiXzo, MLAB, MLLED, MLS, MMI, Mobell, Mobicel, MobiIoT, Mobiistar, Mobile Kingdom, Mobiola, Mobistel, MobiWire, Mobo, Modecom, Mofut, Mosimosi, Motiv, Motorola, Movic, MOVISUN, Movitel, Moxee, mPhone, Mpman, MSI, MStar, MTC, MTN, Multilaser, MultiPOS, MwalimuPlus, MYFON, MyGica, MygPad, Mymaga, MyMobile, MyPhone, Myria, Myros, Mystery, MyTab, MyWigo, Nabi, Nanho, Naomi Phone, NASCO, National, Navcity, Navitech, Navitel, Navon, NavRoad, NEC, Necnot, Nedaphone, Neffos, NEKO, Neo, neoCore, Neolix, Neomi, Neon IQ, Netgear, Netmak, NeuImage, NeuTab, New Balance, New Bridge, Newgen, Newland, Newman, Newsday, NewsMy, Nexa, NEXBOX, Nexian, NEXON, NEXT, Nextbit, NextBook, NextTab, NG Optics, NGM, NGpon, Nikon, NINETEC, Nintendo, nJoy, NOA, Noain, Nobby, Noblex, NOBUX, noDROPOUT, NOGA, Nokia, Nomi, Nomu, Noontec, Nordmende, NorthTech, Nos, Nothing Phone, Nous, Novex, Novey, NOVO, NTT West, NuAns, Nubia, NUU Mobile, NuVision, Nuvo, Nvidia, NYX Mobile, O+, O2, Oale, Oangcc, OASYS, Obabox, Ober, Obi, Odotpad, Odys, OINOM, Ok, Okapia, Oking, OKSI, OKWU, Olax, Olkya, Ollee, OLTO, Olympia, OMIX, Onda, OneClick, OneLern, OnePlus, Onix, Onkyo, ONN, ONYX BOOX, Ookee, OpelMobile, Openbox, Ophone, OPPO, Opsson, Optoma, Orange, Orbic, Orbita, Orbsmart, Ordissimo, Orion, OSCAL, OTTO, OUJIA, Ouki, Oukitel, OUYA, Overmax, Ovvi, Owwo, OYSIN, Oysters, Oyyu, OzoneHD, P-UP, Packard Bell, Paladin, Palm, Panacom, Panasonic, Pano, Panoramic, Pantech, PAPYRE, Parrot Mobile, Partner Mobile, PC Smart, PCBOX, PCD, PCD Argentina, PEAQ, Pelitt, Pendoo, Pentagram, Perfeo, Phicomm, Philco, Philips, Phonemax, phoneOne, Pico, PINE, Pioneer, Pioneer Computers, PiPO, PIRANHA, Pixela, Pixelphone, Pixus, Planet Computers, Platoon, Ployer, Plum, PlusStyle, Pluzz, PocketBook, POCO, Point Mobile, Point of View, Polar, PolarLine, Polaroid, Polestar, PolyPad, Polytron, Pomp, Poppox, POPTEL, Porsche, Positivo, Positivo BGH, PPTV, Premier, Premio, Prestigio, PRIME, Primepad, Primux, Pritom, Prixton, PROFiLO, Proline, Prology, ProScan, Protruly, ProVision, PULID, Punos, Purism, Q-Box, Q-Touch, Q.Bell, QFX, Qilive, QLink, QMobile, Qnet Mobile, QTECH, Qtek, Quantum, Quatro, Qubo, Quechua, Quest, Quipus, Qumo, Qware, R-TV, Rakuten, Ramos, Raspberry, Ravoz, Raylandz, Razer, RCA Tablets, Reach, Readboy, Realme, RED, Redbean, Redfox, RedLine, Redway, Reeder, REGAL, RelNAT, Remdun, Retroid Pocket, Revo, Revomovil, Ricoh, Rikomagic, RIM, Rinno, Ritmix, Ritzviva, Riviera, Rivo, Rizzen, ROADMAX, Roadrover, Roam Cat, ROiK, Rokit, Roku, Rombica, Ross&Moor, Rover, RoverPad, Royole, RoyQueen, RT Project, RugGear, RuggeTech, Ruggex, Ruio, Runbo, Rupa, Ryte, S-TELL, S2Tel, Saba, Safaricom, Sagem, Saiet, Salora, Samsung, Samtech, Samtron, Sanei, Sankey, Sansui, Santin, SANY, Sanyo, Savio, SCBC, Schneider, Schok, Scosmos, Seatel, SEBBE, Seeken, SEEWO, SEG, Sega, Selecline, Selenga, Selevision, Selfix, SEMP TCL, Sencor, Sendo, Senkatel, Senseit, Senwa, Seuic, Sewoo, SFR, SGIN, Shanling, Sharp, Shift Phones, Shivaki, Shtrikh-M, Shuttle, Sico, Siemens, Sigma, Silelis, Silent Circle, Simbans, Simply, Singtech, Siragon, Sirin Labs, SK Broadband, SKG, SKK Mobile, Sky, Skyline, SkyStream, Skyworth, Smadl, Smailo, Smart, Smart Electronic, Smart Kassel, Smartab, SmartBook, SMARTEC, Smartex, Smartfren, Smartisan, Smarty, Smooth Mobile, Smotreshka, SNAMI, SobieTech, Soda, Softbank, Soho Style, SOLE, SOLO, Solone, Sonim, SONOS, Sony, SOSH, Soundmax, Soyes, Spark, SPC, Spectralink, Spectrum, Spice, Sprint, SQOOL, SSKY, Star, Starlight, Starmobile, Starway, Starwind, STF Mobile, STG Telecom, STK, Stonex, Storex, StrawBerry, Stream, STRONG, Stylo, Subor, Sugar, Sumvision, Sunmax, Sunmi, Sunny, Sunstech, SunVan, Sunvell, SUNWIND, SuperBOX, SuperSonic, SuperTab, Supra, Supraim, Surge, Suzuki, Swipe, SWISSMOBILITY, Swisstone, Switel, SWTV, Syco, SYH, Sylvania, Symphony, Syrox, T-Mobile, T96, TAG Tech, Taiga System, Takara, Talius, Tambo, Tanix, TB Touch, TCL, TD Systems, TD Tech, TeachTouch, Technicolor, Technika, TechniSat, Technopc, TechnoTrend, TechPad, TechSmart, Techwood, Teclast, Tecno Mobile, TecToy, TEENO, Teknosa, Tele2, Telefunken, Telego, Telenor, Telia, Telit, Telma, TeloSystems, Telpo, TENPLUS, Teracube, Tesco, Tesla, TETC, Tetratab, teXet, ThL, Thomson, Thuraya, TIANYU, Tibuta, Tigers, Time2, Timovi, TIMvision, Tinai, Tinmo, TiPhone, TiVo, TJC, TOKYO, Tolino, Tone, TOOGO, Tooky, Top House, TopDevice, TOPDON, Topelotek, Toplux, TOPSHOWS, Topsion, Topway, Torex, Torque, TOSCIDO, Toshiba, Touch Plus, Touchmate, TOX, TPS, Transpeed, TrekStor, Trevi, Trident, Trifone, Trio, Tronsmart, True, True Slim, TTEC, TTK-TV, TuCEL, Tunisie Telecom, Turbo, Turbo-X, TurboKids, TurboPad, Turkcell, TVC, TWM, Twoe, TWZ, Tymes, Türk Telekom, U-Magic, U.S. Cellular, UE, Ugoos, Uhans, Uhappy, Ulefone, Umax, UMIDIGI, Unblock Tech, Uniden, Unihertz, Unimax, Uniqcell, Uniscope, Unistrong, Unitech, UNIWA, Unknown, Unnecto, Unnion Technologies, UNNO, Unonu, Unowhy, UOOGOU, Urovo, UTime, UTOK, UTStarcom, UZ Mobile, V-Gen, V-HOME, V-HOPE, v-mobile, VAIO, VALEM, VALTECH, Vankyo, Vargo, Vastking, VAVA, VC, VDVD, Vega, Vekta, Venso, Venstar, Venturer, VEON, Verico, Verizon, Vernee, Verssed, Versus, Vertex, Vertu, Verykool, Vesta, Vestel, VETAS, Vexia, VGO TEL, ViBox, Victurio, VIDA, Videocon, Videoweb, ViewSonic, VIIPOO, Vinabox, Vinga, Vinsoc, Vios, Viper, Vipro, Virzo, Vision Touch, Visual Land, Vitelcom, Vityaz, Viumee, Vivax, VIVIMAGE, Vivo, VIWA, Vizio, Vizmo, VK Mobile, VKworld, Vodacom, Vodafone, VOGA, Volt, Vonino, Vontar, Vorago, Vorcom, Vorke, Vormor, Vortex, Voto, VOX, Voxtel, Voyo, Vsmart, Vsun, VUCATIMES, Vue Micro, Vulcan, VVETIME, Völfen, WAF, Walton, Waltter, Wanmukang, WANSA, WE, Webfleet, Wecool, Weelikeit, Weimei, WellcoM, WELLINGTON, Western Digital, Westpoint, Wexler, White Mobile, Wieppo, Wigor, Wiko, Wileyfox, Winds, Wink, Winmax, Winnovo, Winstar, Wintouch, Wiseasy, WIWA, WizarPos, Wizz, Wolder, Wolfgang, Wolki, Wonu, Woo, Wortmann, Woxter, X-AGE, X-BO, X-Mobile, X-TIGI, X-View, X.Vision, X88, X96, X96Q, Xcell, XCOM, Xcruiser, XElectron, XGIMI, Xgody, Xiaodu, Xiaolajiao, Xiaomi, Xion, Xolo, Xoro, Xshitou, Xtouch, Xtratech, Xwave, XY Auto, Yandex, Yarvik, YASIN, YELLYOUTH, YEPEN, Yes, Yestel, Yezz, Yoka TV, Yooz, Yota, YOTOPT, Youin, Youwei, Ytone, Yu, YU Fly, Yuandao, YUHO, YUMKEM, YUNDOO, Yuno, YunSong, Yusun, Yxtel, Zaith, Zamolxe, Zatec, Zealot, Zeblaze, Zebra, Zeeker, Zeemi, Zen, Zenek, Zentality, Zfiner, ZH&K, Zidoo, ZIFRO, Zigo, ZIK, Zinox, Ziox, Zonda, Zonko, Zoom, ZoomSmart, Zopo, ZTE, Zuum, Zync, ZYQ, Zyrex, öwn

## Maintainers

- Mati Sojka: https://github.com/yagooar
- Ben Zimmer: https://github.com/benzimmer

## Contributors

Thanks a lot to the following contributors:

- Peter Gao: https://github.com/peteygao

## Contributing

1. Open an issue and explain your feature request or bug before writing any code (this can save a lot of time, both the contributor and the maintainers!)
2. Fork the project (https://github.com/podigee/device_detector/fork)
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request (compare with develop)
7. When adding new data to the yaml files, please make sure to open a PR in the original project, as well (https://github.com/piwik/device-detector)

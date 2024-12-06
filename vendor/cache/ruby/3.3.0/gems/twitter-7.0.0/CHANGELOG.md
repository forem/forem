7.0.0
------
* [Add `Twitter::DirectMessageEvent`](https://github.com/sferik/twitter/commit/38f6aaa482dcd5f4982abd811dbe6e21e36c2ae8) ([@FabienChaynes](https://twitter.com/FabienChaynes))
* [Create `Twitter::DirectMessageEvent` with media](https://github.com/sferik/twitter/commit/21478530ec6f8a798717a5ab8b197b895db3bc28) ([@FabienChaynes](https://twitter.com/FabienChaynes))
* [Support for DM welcome messages](https://github.com/sferik/twitter/pull/950) ([@FabienChaynes](https://twitter.com/FabienChaynes))
* [Support for closing `Twitter::Streaming::Connection`](https://github.com/sferik/twitter/commit/89e3543aa06e00eeab7eaf5bdd3a33a6112356b1) ([@okkez](https://twitter.com/okkez))
* [Add `Twitter::REST::Client#create_direct_message_event`](https://github.com/sferik/twitter/commit/b45d545c7ebfd28e4d908037dd3fde04e3c307cf) ([@cyu](https://twitter.com/cyu))
* [Add `Twitter::REST::Client#premium_search`](https://github.com/sferik/twitter/pull/953)
* [Add `Twitter::REST::AccountActivity`](https://github.com/sferik/twitter/pull/939)
* [Update all direct message methods to return `Twitter::DirectMessageEvent`](https://github.com/sferik/twitter/commit/0833471366a33657cd2920850e3928db010eecab) ([@flikglick](https://twitter.com/flikglick))
* [Correctly handle different `Twitter::Error::AlreadyRetweeted` error messages](https://github.com/sferik/twitter/commit/c9bf100eedc89aee43689c17f160025e0f40cfb4) ([@knu](https://twitter.com/knu))
* [Fix proxy setting sample](https://github.com/sferik/twitter/commit/91c037cfb26ac0c9d3099cdeec42d65fe8716b78) ([@nicklegr](https://twitter.com/nicklegr))
* [Add Active Support `presence` methods on `Twitter::NullObject`](https://github.com/sferik/twitter/commit/07a5d7b60f335aefd583dae85ba959235bc9f55f) ([@davebrace](https://twitter.com/davebrace))
* [Upload GIFs over 5MB in chunks](https://github.com/sferik/twitter/commit/ba6a3062782b37cf83b9813c5128c87d4971ab9c) ([@wild_dmitry](https://twitter.com/wild_dmitry))
* [Track rate limit when searching tweets](https://github.com/sferik/twitter/commit/067e751d58b7bb0bfbe8a5531a4288f4c966b301) ([@dsalahutdinov1](https://twitter.com/dsalahutdinov1))
* [Add `quote_count` and `reply_count` attributes to `Twitter::Tweet`](https://github.com/sferik/twitter/commit/844818cad07ce490ccb9d8542ebb6b4fc7a61cb4)
* [Drop support for Ruby 2.0, 2.1, and 2.2](https://github.com/sferik/twitter/commit/95861ec83e582c2a88499b97d9d5388a96d0abf0)

6.2.0
------
Not yet documented, sorry. For now, please use git to compare tags:
https://github.com/sferik/twitter/compare/v6.1.0...v6.2.0

6.1.0
------
Not yet documented, sorry. For now, please use git to compare tags:
https://github.com/sferik/twitter/compare/v6.0.0...v6.1.0

6.0.0
------
* [Drop support for Ruby 1.8.7 and Ruby 1.9.3](https://github.com/sferik/twitter/commit/27980f45fb357e34b86e46cb9134d86ed29b3ce3)

5.16.0
------
* [Add Twitter::Trend#tweet_volume](https://github.com/sferik/twitter/commit/e797b62e5e6a768e8aeafde6186e1f5310e6bfc6)
* [Add new settings to Twitter::Settings](https://github.com/sferik/twitter/commit/d047ce00034d26a99927076c28679ce08fd69308)
* [Fix `Version.to_a`](https://github.com/sferik/twitter/commit/0cd119abf64e6c2b7fd861b0df65b7cb41d892b4)
* [Remove the encoding of profile urls](https://github.com/sferik/twitter/commit/6d46bd689ab4a4f119d1d692488aab37e4e99893)
* [Update http dependency to ~> 1.0](https://github.com/sferik/twitter/commit/8d379a45be6948a9d9264aa2e91ef5f7bdbe1db8)
* [Fetch host and port directly from the request object](https://github.com/sferik/twitter/commit/f9f1bbdabde2ec96dcdd8900fe7bca072f9bea6b)

5.15.0
------
* [`NullObject#as_json` returns 'null'](https://github.com/sferik/twitter/commit/2979e703c09a45f012cb2c5b2d6663bf1f4d3351) ([@lukevmorris](https://twitter.com/lukevmorris))
* [Add methods to get to parameters of quoted tweet](https://github.com/sferik/twitter/commit/afd41a3e36cc94194a2110ba9adce13486ced9fd) ([@couhie](https://twitter.com/couhie))
* [Add additional mime_types for multi-part upload](https://github.com/sferik/twitter/commit/947fcdc9f7348f267d74933ffa43d191cf248a9c)
* [Fix bug where flat_pmap can return nil](https://github.com/sferik/twitter/commit/e22a5601ec702632510b3e983e50929ceb334b95)
* [Add new error codes](https://github.com/sferik/twitter/commit/1ce6b2f02d0f5f78435ee898e8f5b6d3db18d6f1)

5.14.0
------
* [Add `Twitter::NullObject#respond_to?`](https://github.com/sferik/twitter/commit/438e311d93f382960650e20898203c880ade6b25)
* [Add `Twitter::Media::Video`, `Twitter::Media::VideoInfo`, and `Twitter::Media::Variant`](https://github.com/sferik/twitter/commit/158193f85843ebac7b3188bbad26d73907577f6a)
* [Add `Twitter::Media::AnimatedGif` media entity](https://github.com/sferik/twitter/commit/76cb6645a54969edc7c9195e9e27e3728f5fd683) ([@nidev](https://twitter.com/nidev))

5.13.0
------
* [Deprecate `Twitter::REST::Client#get` and `Twitter::REST::Client#post`](https://github.com/sferik/twitter/commit/65773c7d741098490f4164fae9e4433365cd4292)
* [Rename `Twitter::REST::Client::URL_PREFIX` to `Twitter::REST::Client::BASE_URL`](https://github.com/sferik/twitter/commit/73e2b9be19acf1403f324e5be48a550d3756d822)
* [Extract `Twitter::Headers` class](https://github.com/sferik/twitter/commit/e0d4c36bade95253b98b3ee657af409bfeadbbb6)
* [Move `Twitter::Request` to `Twitter::REST::Request`](https://github.com/sferik/twitter/commit/a46d9f21067724c437d40c7cb9c609f6cd304df1)
* [Add `Twitter::REST::Request#rate_limit`](https://github.com/sferik/twitter/commit/0c9f9d6a15835a0260a5a56a8aaffdc3f3e39eed)
* [Rename `Twitter::REST::Utils` methods](https://github.com/sferik/twitter/commit/2b1cceca0d37a038d3afd0b5763f2308b3db1b2d)
* [Update default `User-Agent` to comply with Section 5.5.3 of RFC 7231](https://github.com/sferik/twitter/commit/e5eb8d451d8be2d2751e6dda132c65039e5c879c)

5.12.0
------
* [Rescue `Twitter::Error::NotFound` for safe `#favorite` and `#retweet`](https://github.com/sferik/twitter/commit/5e6223df20217fd6b0ac78b44b0defdb46d1e018)
* [Make `Twitter::User#profile_background_image_uri` methods return a URI](https://github.com/sferik/twitter/commit/d96194c0c3b17076e48faed1b05cd48d043a6778)
* [Un-deprecate `Twitter::Base#to_hash`](https://github.com/sferik/twitter/commit/f45ce597408ab2bae2b55db6456543bf6d9ea081)
* [Add `Twitter::Tweet#possibly_sensitive?`](https://github.com/sferik/twitter/commit/917e8f14f7707eb646e8057827ed0ba9d1766eeb)
* [Namespace registered Faraday middleware](https://github.com/sferik/twitter/commit/a96931171e32c142f36318547f2cffa6ccd5c199) ([@godfoca](https://twitter.com/godfoca))
* [Fix test failures on Ruby 2.2.0-preview1](https://github.com/sferik/twitter/commit/74fb2e676f5882c62a6d4f07d7bbf8ca1f469fe2)
* [Make Twitter::NullObject Comparable](https://github.com/sferik/twitter/commit/9635db5128708525f3368800f11c519d6b14b1e4)

5.11.0
------
* [Return a Twitter::NullObject for empty attributes](https://github.com/sferik/twitter/commit/bca179eefb1c157f19b882a88ba608f6817b76bb)
* [Add `iso_language_code` attribute to `Twitter::Metadata`](https://github.com/sferik/twitter/commit/7bf3a1b6ad0c35dc608b03ba2b3321b594e4da1c)

5.10.0
------
* [Add support for extended entities](https://github.com/sferik/twitter/commit/ed7c708e4208de1df27d141678c14e23422504a0)
* [Add `Twitter::REST::Client#upload`](https://github.com/sferik/twitter/commit/f5a747b53c4866bb378d6022f309d6176620122e)

5.9.0
-----
* [Use expanded URIs when available](https://github.com/sferik/twitter/commit/f1d5d1f4c0ea75ebeaf9e7eb760b9efd245a5df2)
* [Deprecate `Twitter::REST::Client#middleware=` and `#connection_options`](https://github.com/sferik/twitter/commit/2ec17d8d43a87766dd4b89fcc6d5a2433530bf7c)
* [Ensure predicate methods return `false` for `Twitter::NullObject`](https://github.com/sferik/twitter/commit/f1b42bf82440f2dc0ba61761fc8f12460e20aadf)
* [Make `Twitter::Place#id` attribute accessible](https://github.com/sferik/twitter/commit/a4fa4739283a325886d44f97b2648e3b00f933b1)
* [Enable injection of custom TCP/SSL socket classes](https://github.com/sferik/twitter/commit/3629a1edfbc6b35099d4b0fc165b938a67c02d86) ([@neektza](https://twitter.com/neektza))
* [Deprecate predicate methods without question marks](https://github.com/sferik/twitter/commit/0305a8535357b6114be73e6b94744eed6b6d3bb5)
* [Deprecate `Twitter::Base#[]`](https://github.com/sferik/twitter/commit/2ab6c0d546b7c1d3635ac9c319fb5c2aa2514da0)
* [Remove statement that TweetStream is not 2.0.0-compatible](https://github.com/sferik/twitter/pull/553) ([@melaniegilman](https://twitter.com/melaniegilman))
* [Dont allow unacceptable IO objects in `Twitter::REST::Client#update_with_media`](https://github.com/sferik/twitter/commit/f22f1e2efd29200f157af041a470678cd4ef637a) ([@tim_linquist](https://twitter.com/tim_linquist))
* [Add support for new REST API endpoint for bulk lookup of Tweets by ID](https://github.com/sferik/twitter/commit/0d23c5ed65a7e7728cd096d611e5edeecdbc6e79)
* [Make the streaming API raise exceptions for status codes](https://github.com/sferik/twitter/commit/b571e03ed18cd63ec1d1a57c03e5744b284111d6) ([@eroberts](https://twitter.com/eroberts))
* [Call GET users/show if screen name has already been fetched](https://github.com/sferik/twitter/commit/0691a62ca5b43d33aa2f7b63aeb039d9155a24ed)
* [Add the ability to set user_agent and proxy](https://github.com/sferik/twitter/commit/e72185e1b0299221448650760b91c74ff1bec3e7)
* [Use (immutable) user ID instead of (mutable) screen name](https://github.com/sferik/twitter/commit/ceeccb08bbc7cc65c3e6eddaf408b236b8a98677)
* [Implement mute functionality](https://github.com/sferik/twitter/commit/dfe206cae5f2189ce2b5cd5db6307d5d5e8af4ef)

5.8.0
-----
* [Alias `Twitter::Tweet#reply?` to `Twitter::Tweet#in_reply_to_user_id?`](https://github.com/sferik/twitter/commit/57147287d25e21a5e740ee69c3e9aeec6abd1b06)
* [Add `Twitter::Error::SSL_REQUIRED` error code](https://github.com/sferik/twitter/commit/0cb7e6c132b73766bc978ccb45dd8d9cba43f660)
* [`Twitter::Tweet#retweeted_status` always returns the original tweet, not the retweet](https://github.com/sferik/twitter/commit/70fede7fa09a87b7e1cba5b8b4be82127c9eaf51) ([@IanChoiJugnoo](https://twitter.com/IanChoiJugnoo))

5.7.1
-----
* [Only warn if entities are not included](https://github.com/sferik/twitter/commit/82ed19e69c03ccaccc366744421b3bb3ee444625) ([@matthewrudy](https://twitter.com/matthewrudy))
* [Fix typos in documentation](https://github.com/sferik/twitter/pull/531) ([@attilaolah](https://twitter.com/attilaolah))

5.7.0
-----
* [Remove `Twitter::Base.from_response` method](https://github.com/sferik/twitter/commit/6f9a352adaa5eee0611fa8d2e45fc7349b5cecae)
* [Remove `Twitter::REST::API` namespace](https://github.com/sferik/twitter/commit/f9c4e8214bfe0e4cbd13681a6454956f2c6ac21b)
* [Remove `descendants_tracker`](https://github.com/sferik/twitter/commit/4cbcb0fc58c55b84b642bc7c66085bb581e9b20a)
* [Remove unused `HTTP_STATUS_CODE` constants](https://github.com/sferik/twitter/commit/b45d89bc96f11079b31976f14ade4f89d50b4dc9)
* [Remove `Twitter::Error#cause`](https://github.com/sferik/twitter/commit/a5748b925aa3220e7388311bd0228a62d45d09a4)

5.6.0
-----
* [Replace custom `Twitter::NullObject` with `Naught`](https://github.com/sferik/twitter/commit/bc3990e3588f889569f1c92e465c329c508ce32e)
* [Use `URI` and `CGI` to convert query string into a hash](https://github.com/sferik/twitter/commit/6dd9d97aaef3917868b870e01896ab937cbacfbb)
* [Increase default timeout values](https://github.com/sferik/twitter/commit/350536926d1c2c0656fdc79948c5f543e306e14e)
* [Add `Twitter::Error::RequestTimeout`](https://github.com/sferik/twitter/commit/3179537af41b2e2f85c0bc74be799faea0817e48)
* [Remove unused methods `#put` and `#delete` in `Twitter::REST::Client`](https://github.com/sferik/twitter/commit/eaaf234b84a6e2e1f7695f73befaf11f30664f4a)
* [Deprecate `retweeters_count` in favor of `retweet_count`](https://github.com/sferik/twitter/commit/ea39bd013364dc24f02e9a1eb25b4b48b99a5480)
* [Deprecate `favorites_count`/`favoriters_count` in favor of `favorite_count`](https://github.com/sferik/twitter/commit/ea39bd013364dc24f02e9a1eb25b4b48b99a5480)
* [Deprecate `to_hsh` in favor of `to_hash` or `attrs`](https://github.com/sferik/twitter/commit/63e2cdd693aece2912564988d06786cd23a2cad5)
* [Deprecate `oauth_token` and `oauth_token_secret` accessors](https://github.com/sferik/twitter/commit/ac246717557ea02565a1d93b3f9a975e7fd39874)

5.5.1
-----
* [Fix bug where `Twitter::Error::AlreadyFavorited` would never be raised](https://github.com/sferik/twitter/issues/512) ([@polestarw](https://twitter.com/polestarw))
* [Fix bug where `Twitter::Error::AlreadyPosted` would never be raised](https://github.com/sferik/twitter/commit/e6b37b930c056a88d8ee1477246635caf579111d)
* [Restore `Twitter::Entities#entities?` as a public method](https://github.com/sferik/twitter/commit/234a9e3134eeee072bd511e1c1f1823ceb1531a2)

5.5.0
-----
* [Add entities to `Twitter::DirectMessage`](https://github.com/sferik/twitter/commit/d911deb456cb2da6e14d0b3c69ba4d068ca85868)
* [Add conversion methods to `Twitter::NullObject`](https://github.com/sferik/twitter/commit/4900fee474feaa1514c06d459a9da6d52c45a60e)

5.4.1
-----
* [Default to maximum number of tweets per request](https://github.com/sferik/twitter/commit/1e41b5d4dde8678f5968b57dafe9da63b092646c)

5.4.0
-----
* [Fix enumerable search interface](https://github.com/sferik/twitter/commit/e14cc3391ebe8229184e9e83806c870df3baa24c)

5.3.1
-----
* [Add `Twitter::Utils` module](https://github.com/sferik/twitter/commit/a1f47fbf19b859c8e680a0a92eff5e225a015090) ([@charliesome](https://twitter.com/charliesome))
* [Remove `Enumerable` monkey patch](https://github.com/sferik/twitter/commit/818b28d1621e843c0c6f9ef471076f4125623e52) ([@charliesome](https://twitter.com/charliesome))
* [Don't spawning a new thread if there's only one element](https://github.com/sferik/twitter/commit/c01ea8309c16eb77eeb368452df1dadd1e405532)
* [Introduce meaningful constant names](https://github.com/sferik/twitter/commit/215c80890d702535de83d8f849885a95ec153920) ([@futuresanta](https://twitter.com/futuresanta))
* [Automatically flatten `Twitter::Arguments`](https://github.com/sferik/twitter/commit/a556028ace04cb00c3c2b9cb8f72f792a86f04d6)

5.3.0
-----
* [Add `UNABLE_TO_VERIFY_CREDENTIALS` error code](https://github.com/sferik/twitter/commit/6a47e715ef7935cd36a2f78ed877deb3c09af162)
* [Don't suppress `Twitter::Error::Forbidden` in #follow and #follow!](https://github.com/sferik/twitter/commit/b949c0400dabc6774419025e7b131d0a18447c3a)
* [Update memoizable dependency to ~> 0.3.1](https://github.com/sferik/twitter/pull/501)

5.2.0
-----
* [Replace `URI` with `adressable`](https://github.com/sferik/twitter/commit/7ea2f5390dc7456950f55c90aa4e48f29dcd4604)
* [Make `Twitter::Streaming::FriendList` an array](https://github.com/sferik/twitter/commit/1a38e5e8182823c3060fc59c270ef754bd49a179)
* [Add `Twitter::Streaming::DeletedTweet`](https://github.com/sferik/twitter/commit/084025b5e348bd33b4c29c6b9e40565c0e77319c)
* [Add `Twitter::Streaming::StallWarning`](https://github.com/sferik/twitter/commit/b07ac50552f5063ee43a490fa40da8b6889df772)
* [Add error code for "User is over daily status update limit"](https://github.com/sferik/twitter/commit/76c088d38e594703ee391f2a524142aa357b0972)
* [`Twitter::Streaming::Client#site` can take a `String` or `Twitter::User`](https://github.com/sferik/twitter/commit/e3ad4f2da1f8fc82e1d3febbc2602f626bced8a8)
* [Update `http_parser.rb` dependency to `~> 0.6.0`](https://github.com/sferik/twitter/commit/6d2f81bfc5bd469d558868a0f65356f30ca9f5e7)

5.1.1
-----
* [Custom equalizer for `Twitter::Place`](https://github.com/sferik/twitter/commit/79c76a9bed4f0170c8c09fe38ad4f0ee6aa4505e)

5.1.0
-----
* [Use `Addressable::URI` everywhere](https://github.com/sferik/twitter/commit/97d7c68900c9974a1f6841f6eed2706df9030d64) ([@matthewrudy](https://twitter.com/matthewrudy))
* [Allow use of `Twitter::Place` instead of `place_id`](https://github.com/sferik/twitter/commit/c2b31dd2385fefa30a9ddccf15415a713cf5953a)
* [Allow use of `Twitter::Tweet` instead of `in_reply_to_status_id`](https://github.com/sferik/twitter/commit/6b7d6c2b637a074c348a56a51fb1e02252482fb2)

5.0.1
-----
* [Fix `buftok` delimiter handling](https://github.com/sferik/twitter/pull/484)
* [Started handling streaming deletes](https://github.com/sferik/twitter/commit/8860b97bce4bc36086116f380a2771af3c199ea2)

5.0.0
-----
* [Remove `Twitter::API::Undocumented#status_activity` and `#statuses_activity`](https://github.com/sferik/twitter/commit/7f970810af251b2fe80c38b30c54485c55bd2034)
* [Remove `Twitter::Tweet#favoriters`, `#repliers`, `#repliers_count`, and `#retweeters`](https://github.com/sferik/twitter/commit/77cc963381a68e8299ef6c6b7a306b440666d792)
* [Remove identity map](https://github.com/sferik/twitter/commit/ec7c2df78a200e2b0b1cd3a40983c6ce9dee552d)
* [Remove `Twitter::Cursor#all`](https://github.com/sferik/twitter/commit/72be4148b973153c6d3044c406b768ad832555ff)
* [Remove `Twitter::Cursor#collection`](https://github.com/sferik/twitter/commit/9ae4621610ba6c26950e6b77f950f698cdfc8dac)
* [Remove `Twitter#from_user`](https://github.com/sferik/twitter/commit/d2ae9f1cc1f5224bcdff06cda65fabdf9e7fbcb3)
* [Remove `ClientError`, `ServerError`, and `ParserError`](https://github.com/sferik/twitter/commit/72843948d8a6f66345adc254fa91cf1097592b22)
* [Remove global configuration](https://github.com/sferik/twitter/commit/239c5a8462fabb8c8ef9ec6a4cdded34561d572d)
* [Remove ability to configure client with environment variables](https://github.com/sferik/twitter/commit/17e958579f65abf8932841f20058a5989abb994f)
* [Remove Brittish English aliases](https://github.com/sferik/twitter/commit/572813b373a1c3001ff6c1bb729f092434d17bab)
* [Replace `multi_json` with `json`](https://github.com/sferik/twitter/commit/e5fc292fee078567664acf6be4ed31a8ad077780)
* [Rename `oauth_token` to `access_token`](https://github.com/sferik/twitter/commit/d360f8015c487c4599460abd0dd0bc7e59a522a3)
* [Move `Twitter::Arguments` out of `REST::API` namespace](https://github.com/sferik/twitter/commit/8faa15309d906dd46fccc1b914ea4aa7a5da7c2d)
* [Move `Twitter::Client` into `REST` namespace](https://github.com/sferik/twitter/commit/5b8c3fd243227888fc0886b0bf864ecd3a018f99)
* [Add `Twitter::Streaming::Client`](https://github.com/sferik/twitter/commit/23afe90aa494229a4389c3e51f753102b34fc551)
* [Add `Twitter::Error::AlreadyPosted`](https://github.com/sferik/twitter/commit/e11d2a27dd0dfbbe16c812a81b9c2ab2852a7790)
* [Add `Twitter::REST::Client#reverse_token`](https://github.com/sferik/twitter/commit/39139c4df35b54b86fae29d1ac83a08f4aa293cd)
* [Add `#url` methods to `Twitter::List`, `Twitter::Tweet`, and `Twitter::User`](https://github.com/sferik/twitter/commit/a89ec0f4e81097cc303b6c204e0375eb57ffd614)
* [Add `Twitter::Place#contained_within` and `#contained_within?`](https://github.com/sferik/twitter/commit/23cc247bd20001ecbafa544bfb4546bdfc630429)
* [Add `Twitter::GeoResults`](https://github.com/sferik/twitter/commit/be1a0a1425a6700267aae0f94a8835bff24dad56)
* [Add `NullObject`](https://github.com/sferik/twitter/commit/17880f491726cee77c1cbcf914887e95d5e6ae7e)
* [Add predicate methods for any possible `NullObject`](https://github.com/sferik/twitter/commit/eac5522edededacfc2a22d6f6879da43b8136d41)
* [Always return `URI` instead of `String`](https://github.com/sferik/twitter/commit/341f68d1a46667a820754d30ffa6ec2f50034afc)
* [Allow `URI` as argument](https://github.com/sferik/twitter/commit/c207567e674f108e4074e12c9e7343fb74e8a97c)
* [Allow `String` in addition to `URI` objects](https://github.com/sferik/twitter/commit/89a46fbd3560109da87d5f87262dcf6bd2a336c6)
* [Collection caching](https://github.com/sferik/twitter/commit/d484d7d7d7a0956f9b4fa6791a911ed7c9522cba)
* [Implement `Twitter::Cursor#each` without making an extra HTTP request](https://github.com/sferik/twitter/commit/8eeff57f5c6d6ca0a6f1ff5ebc31e652a71fc150)
* [Make `Twitter::SearchResults` enumerable](https://github.com/sferik/twitter/commit/d5ce8537164912e79dffc5a054ecd9ae6ecb8075)
* [Make `Twitter::Base` objects immutable](https://github.com/sferik/twitter/commit/69b1ef7edad32398b778c8449bc3605739a6c59a)
* [Missing key now raises `KeyError`, not `ArgumentError`](https://github.com/sferik/twitter/commit/f56698caff608527b9f3c2c3dd4c18306589cb3b)
* [Use `equalizer` instead of manually overwriting #==](https://github.com/sferik/twitter/commit/a7ddf718b119e9c5fc8b87e6784e8c3304707a72)
* [Give methods more natural names](https://github.com/sferik/twitter/commit/e593194fb7bd689fca561e6334db1e6af622590a)
* [Fix `Twitter::SearchResults#rpp` return value](https://github.com/sferik/twitter/commit/28d73200490ac2755c3e68d8d273fbc64a8d7066)

4.8.1
-----
* [Ignore case of profile image extension](https://github.com/sferik/twitter/commit/73760610e959ae868de23de3da661d237fbcb106)
* [Allow use of Twitter::Token in place of bearer token string](https://github.com/sferik/twitter/commit/13596bc60db36ecaf5a1df09ecb322d85d8c2922)
* [Add Twitter::API::Undocumented#tweet_count](https://github.com/sferik/twitter/commit/795458a25ec7b143a995e7f2f2043e523c11961c)
* [Add missing dependencies](https://github.com/sferik/twitter/commit/e07e034472df8b7aa44c779371cf1e25d8caa77d) ([@tmatilai](https://twitter.com/tmatilai))

4.8.0
-----
* [Add `Twitter::SearchResults#refresh_url`](https://github.com/sferik/twitter/commit/6bf08c008de139aad3ec173461e8633bfa5a3bd8) ([@mustafaturan](https://twitter.com/mustafaturan))
* [Fix issue with wrong signature being generated when multipart data is posted](https://github.com/sferik/twitter/commit/65ab90a6d51755e5901434a3568f8163ca3e262f) ([@mustafaturan](https://twitter.com/mustafaturan))
* [Restore compatibility with Ruby 1.8.7](https://github.com/sferik/twitter/commit/fb63970c1bd19792955d092a38b6adf53b558ec7)
* [Remove undocumented methods, retired in the APIpocalypse](https://github.com/sferik/twitter/commit/cf6a91f8df833dce5bffc7a0292402860e7d4da7)

4.7.0
-----
* [Add support for application-only authentication](https://github.com/sferik/twitter/pull/387) ([@paracycle](https://twitter.com/paracycle))
* [Add support for `Twitter::Entity::Symbol` entities](https://github.com/sferik/twitter/commit/a14a0cdc57ad5d7760392f71a280c7100a5b5936) ([@anno](https://twitter.com/anno))
* [Add `Twitter::API::OAuth#invalidate_token`](https://github.com/sferik/twitter/pull/372) ([@terenceponce](https://twitter.com/terenceponce))
* [Add `Twitter::API::Lists#lists_owned` method](https://github.com/sferik/twitter/commit/9e97b51c20aabf4485a91ae7db697ee3be131a89)
* [Add `Twitter::API::Tweets#retweeters_ids` method](https://github.com/sferik/twitter/commit/8cf5b2ddf3d2647084496c7c3f205b2468d84cbe)
* [Add `Twitter::SearchResults#next_results`](https://github.com/sferik/twitter/pull/365) ([@KentonWhite](https://twitter.com/KentonWhite))
* [Make consumer_key readable](https://github.com/sferik/twitter/commit/a318869c4827d6add781730cfb67fd2bdca5c584)
* [Loosen required_rubygems_version for compatibility with Ubuntu 10.04](https://github.com/sferik/twitter/commit/41bd5655c2e7eca813807d742cb7fdec8f0bb027)
* [Remove default SSL configuration options and override](https://github.com/sferik/twitter/commit/113b14bc05a9f8e513245fda057e7f16f8965357)

4.6.2
-----
* [Fix `SystemStackError: stack level too deep` when converting to JSON](https://github.com/sferik/twitter/issues/368)
* [Add `Twitter::Tweet#favorite_count`](https://github.com/sferik/twitter/commit/de8a356d0d5e757bfe383b58744efa1c2d842b79)
* [Add `Twitter::SearchResults#next_results?`](https://github.com/sferik/twitter/commit/d951db4bdaa1ef72383f2026ec6236a289ee9074) ([@KentonWhite](https://twitter.com/KentonWhite))

4.6.1
-----
* [Convert nested classes in `Twitter::Base#attrs`](https://github.com/sferik/twitter/commit/e56c34c640189eb8b25a16994676a5e82b783cb3) ([@anno](https://twitter.com/anno))

4.6.0
-----
* [Make `Twitter::Base#attrs` call methods if they exist](https://github.com/sferik/twitter/commit/ff4f2daccd1acdfddcea7139d4dd6490b55129db)
* [Allow `Twitter::API::Tweets#oembed` and `Twitter::API::Tweets#oembeds` to take a URL](https://github.com/sferik/twitter/commit/0d986fa4b0c254e8c816bce086c3f6648d8fd3d7) ([@bshelton229](https://twitter.com/bshelton229))
* [Add `Twitter::Tweet#filter_level` and `Twitter::Tweet#lang` attribute readers](https://github.com/sferik/twitter/commit/283aafbe1219e55f19a76517d9edce497001fca2)
* [Add "Quick Start Guide" to the `README`](https://github.com/sferik/twitter/commit/afc24ee1bd07f19ef7fb8fd6b85aede34f3ab156) ([@coreyhaines](https://twitter.com/coreyhaines))

4.5.0
-----
* [Add no_retweet_ids](https://github.com/sferik/twitter/commit/cab8d6ebf3afdbd24463932262798a132d70a6f1) ([@tibbon](https://twitter.com/tibbon))

4.4.4
-----
* [Fix documentation bugs](https://github.com/sferik/twitter/commit/45213d16efda0bd78e8c4c3c80892b824393e37c)
* [Relax `multi_json` dependency](https://github.com/sferik/twitter/commit/46327e740a03ec783cb62863d40eef5efa68c0cb)

4.4.3
-----
* [Add `Twitter::API::Arguments` class; remove `extract_options!` helper method](https://github.com/sferik/twitter/commit/65972c599ced8da27fbbfa72aeead92464355583)
* [Ensure credentials set via `Twitter.configure` are of a valid type](https://github.com/sferik/twitter/commit/fc152dbe56b99639896bcaaf7fe158659e8c50b9)
* [Delegate `Twitter::Tweet#profile_image_url` and `Twitter::Tweet#profile_image_url_https` to `Twitter::Tweet#user`](https://github.com/sferik/twitter/commit/7bd6f8f589a91a8c82363d07da77ec012890c6cb)
* [Fix timeout bug; lock `faraday` dependency to version < 0.10](https://github.com/sferik/twitter/commit/01e2781e4a78137ca4e5e6d3e4faf2552ee9ec76)

4.4.2
-----
* [Fix to `Twitter::API::FriendsAndFollowers#friends` and `Twitter::API::FriendsAndFollowers#followers`](https://github.com/sferik/twitter/commit/d97438f5de89a1a15ad8ff5e67e8e0c7d412911f) ([@nbraem](https://twitter.com/nbraem))
* [Alias `Twitter::DirectMessage#text` to `Twitter::DirectMessage#full_text`](https://github.com/sferik/twitter/commit/dde92816beac5076507b3c0fb5b036222e2a4889)
* [Remove `Kernel#calling_method`](https://github.com/sferik/twitter/commit/045d6e17178520641509f884ed4ce4e4f2f765fb)

4.4.1
-----
* [Do not modify `Thread.abort_on_exception`](https://github.com/sferik/twitter/commit/6de998ced1f3dce97a24e500ecf2348192ae9316)

4.4.0
-----
* [Add `Twitter::API::FriendsAndFollowers#friends` and `Twitter::API::FriendsAndFollowers#followers`](https://github.com/sferik/twitter/commit/03e1512a8e5e589771414aaf46db34718f1469ce) ([@tibbon](https://twitter.com/tibbon))
* [Add `method` parameter to `Twitter::API::Users#users`](https://github.com/sferik/twitter/commit/4885c8df5f36fcbe39bd435ef12b6e0bed06dcb5) ([@thomasjklemm](https://twitter.com/thomasjklemm))
* [Correct endpoint of `Twitter::Client#report_spam` method](https://github.com/sferik/twitter/commit/e59c0c4c31a9f7eed3d202c276628a3ea0df6d28) ([@uasi](https://twitter.com/uasi))
* [Refactor `Twitter::Request` class](https://github.com/sferik/twitter/commit/2d70b64674bdc204c85c47327afa571f9641e545)
* [Remove `Array` core extensions](https://github.com/sferik/twitter/commit/2d00f99f4ac43e13e24bf90fcc813252175273f2)
* [Remove `String` core extensions](https://github.com/sferik/twitter/commit/5a9144c3f5104a7ee13b4c50f32cf71151004023)
* [Remove `Hash` core extensions](https://github.com/sferik/twitter/commit/0a8591efce268119e29623317382a1f2de2d0aa6)
* [Do not `require 'identity_map'` by default](https://github.com/sferik/twitter/commit/da38eec199222ae2292650313ce153e2b3986369)
* [Automatically define inquirer methods](https://github.com/sferik/twitter/commit/a6da19baf82656af118a4ec27e845b46c22a3d7e)


4.3.0
-----
* [Add Twitter::API#profile_banner](https://github.com/sferik/twitter/commit/5879ef3fcc486ac3849426ef0d44ee0288ed9599)

4.2.0
-----
* [Use new resource for `Twitter::API#retweets_of_me`](https://github.com/sferik/twitter/commit/d88ca1e91af06e748c31dcda287326028cf28258)
* [`Twitter::API#favorite` no longer raises `Twitter::Error::Forbidden`](https://github.com/sferik/twitter/commit/65c01133a96106a6b0c61bc16cb2ffec38fa5e25)
* [`Twitter::API#retweet` no longer raises `Twitter::Error::Forbidden`](https://github.com/sferik/twitter/commit/f1322ab12c573229ea3dc8decda2e2ea8b36fc31)
* [Add `Twitter::Error::AlreadyFavorited`](https://github.com/sferik/twitter/commit/34710927e00d4dc5abc049bfc198bdd337fba1bd)
* [Add `Twitter::Error::AlreadyRetweeted`](https://github.com/sferik/twitter/commit/2a231a0888dcd65dbef2dc92571e06d50f845cca)

4.1.2
-----
* [Add abort_on_exception to `Enumerable#threaded_map`](https://github.com/sferik/twitter/commit/15c9a7c221f24226c1003b76b287d2b2ed9306cb) ([@aheaven87](https://twitter.com/aheaven87))

4.1.1
-----
* [Fix bug in `Twitter::Tweet#full_text`](https://github.com/sferik/twitter/commit/9646a5bed6d2d119b1cc1d5757113988de2516d6)
* [Add `Twitter::Tweet#favouriters`, `Twitter::User#favoriters_count`, and `Twitter::User#favouriters_count` aliases](https://github.com/sferik/twitter/commit/60fce1ea0cdf8239262ca46588b4fe766f07288e)

4.1.0
-----
* [Handle new API v1.1 list response format](https://github.com/sferik/twitter/commit/2aace25fcf946de995e5ce1788f24ad35bc79438)

4.0.0
-----
* [Update all endpoints to Twitter API v1.1](https://github.com/sferik/twitter/commit/f55471a03dd0a428d5c0aa57a3c34809dbfde5cf)
* [Replace `per_page` parameter with `count`](https://github.com/sferik/twitter/commit/e112ce6f779ca2a204a86caf71a11125a65de961)
* [Use HTTP POST for `users/lookup`](https://github.com/sferik/twitter/commit/ff68ff81a8586d70fa021afaed6ff261d2a4b178)
* [Add error classes for new Twitter API v1.1 response codes](https://github.com/sferik/twitter/commit/154b00f8c0cbbcf9177d367f19a90ef256d5b6a4)
* [Cache `screen name` in an instance variable to avoid API calls](https://github.com/sferik/twitter/commit/dfc5641511bd99da857bf524af8449afb1843f8e)
* [Update `Twitter::RateLimit` class for API v1.1](https://github.com/sferik/twitter/commit/540cbb2d90f3b2c53f09a9727cbad1d2489e3fae)
* [Remove search endpoint](https://github.com/sferik/twitter/commit/37610fe6d54686238aedaee53914e70e67040d59)
* [Remove media endpoint](https://github.com/sferik/twitter/commit/e4a70152b1a6f00299d3b659497c02adb791c18f)
* [Disable identity map by default](https://github.com/sferik/twitter/commit/c6c5960bea998abdc3e82cbb8dd68766a2df52e1)
* [Remove deprecated `RateLimit.instance` method](https://github.com/sferik/twitter/commit/bf08485942428c26ba595c4e092dcdac1ec823ff)
* [Removed deprecated `Twitter::Tweet#oembed` method](https://github.com/sferik/twitter/commit/16f09cf7053f2109a740ea43461e89b504335c50)
* [Rename resources for v1.1](https://github.com/sferik/twitter/commit/03c4c143082fc1e7b2355d77d98da77f401fddd4)
* [Remove notification methods; use `Twitter::API#friendship_update` instead](https://github.com/sferik/twitter/commit/3b2d2b86599b4d054e7daa0d69b5e088cd776450)
* [Remove `Twitter::API#end_session`](https://github.com/sferik/twitter/commit/23668bc68209a032e9193ade1cdf6d8462980954)
* [Add `Twitter::Tweet#retweet?` method and `Twitter::Tweet#retweet` alias](https://github.com/sferik/twitter/commit/1e6ad051f488cae7bf18a45eea8008b448323fe4)
* [Major changes for Twitter API v1.1](https://github.com/sferik/twitter/commit/eab13be653c1b54aa679dbf16f252a2b6977b80e)
* [Remove `Twitter::API#no_retweet_ids`](https://github.com/sferik/twitter/commit/e179ab6d81c1c4931b67940463f414693671fb96)
* [Remove `Twitter::API#retweeted_to_user`](https://github.com/sferik/twitter/commit/e179ab6d81c1c4931b67940463f414693671fb96)
* [Remove `Twitter::API#trends_daily`](https://github.com/sferik/twitter/commit/e179ab6d81c1c4931b67940463f414693671fb96)
* [Remove `Twitter::API#trends_weekly`](https://github.com/sferik/twitter/commit/e179ab6d81c1c4931b67940463f414693671fb96)
* [Remove `Twitter::API#rate_limited?`](https://github.com/sferik/twitter/commit/b2ec0107bc1a2a73bd6b004348f1e6413822845c)
* [Remove `Twitter::Client#rate_limit`](https://github.com/sferik/twitter/commit/3a4be52a50ad20875b1cf48871f7754944593c95)
* [Remove `Twitter::API#rate_limit_status`](https://github.com/sferik/twitter/commit/ffebee6638875d5cc8363599fcfab2058bf1baf9)
* [Remove `Twitter::API#accept`](https://github.com/sferik/twitter/commit/e4bcec169faafb78772e60d6cdeb5583a40f32e3)
* [Remove `Twitter::API#deny`](https://github.com/sferik/twitter/commit/e4bcec169faafb78772e60d6cdeb5583a40f32e3)
* [Remove `Twitter::API#related_results`](https://github.com/sferik/twitter/commit/e4bcec169faafb78772e60d6cdeb5583a40f32e3)
* [Remove `Twitter::API#recommendations`](https://github.com/sferik/twitter/commit/e4bcec169faafb78772e60d6cdeb5583a40f32e3)
* [Remove `Twitter::API#network_timeline`](https://github.com/sferik/twitter/commit/93c65f25eafb3051a86140ab7e980d03431040f1)

3.8.0
-----
* [Do not attempt to parse redirects](https://github.com/sferik/twitter/commit/30ee1c733cfea091f60b18a51d01eab1d0cc6f30) ([@twoism](https://twitter.com/twoism))
* [Add profile banner methods to `Twitter::User` class](https://github.com/sferik/twitter/commit/d0200d72e71639ad3e7f7e2b7243889f2f39e8b3)
* [Add `Twitter::Error::UnprocessableEntity`](https://github.com/sferik/twitter/commit/fca4d174e8237655c82992edf67fcc846497fd54)
* [Add `Twitter::API#update_profile_banner` and `Twitter::API#remove_profile_banner`](https://github.com/sferik/twitter/commit/74b17f58549b06885ab49c56271cb571886e67f0)
* [Add `Twitter::Tweet#reply?`](https://github.com/sferik/twitter/commit/029d815815c99a7921a9b396c6c45b9f4cbd8fc3)

3.7.0
-----
* [Remove support for `IO` hash syntax](https://github.com/sferik/twitter/commit/bfe842d714a77b8edda90d0e2b547be434dc0148)
* [Allow `Tempfile` to be passed to `Twitter::API#update_with_media`](https://github.com/sferik/twitter/commit/79dc8197250f0416a9a44524be0aaea9d3f31d83)
* [Set `Content-Type` header to `multipart/form-data` when uploading a file](https://github.com/sferik/twitter/commit/24f759b7a128de2bceff27ee0e4699e8d927e5a5)
* [Do not attempt to parse bodies that only contain spaces](https://github.com/sferik/twitter/commit/2a191ea051b20a492a3325413dcdca11b593ba50)
* [Add `Twitter::Tweet#entities?` method](https://github.com/sferik/twitter/commit/43221b1d5fc1a3333a4718c79fd95f9ad42f143e)
* [Add `Twitter::User#status?` method](https://github.com/sferik/twitter/commit/255dc305ed886ac1e062b96001cb09484e5ad98d)

3.6.0
-----
* [Rename Twitter::Status to Twitter::Tweet](https://github.com/sferik/twitter/commit/6d25887ecd371b9deaf4b70bc2f2ee1e6bff98bc)
* [Make Twitter::Cursor an Enumerable](https://github.com/sferik/twitter/commit/2582f2ed3518a11bcad150778da18618dd9a0d37)
* [Always define respond_to_missing? when overriding method_missing](https://github.com/sferik/twitter/commit/23cfaf9dec4bc58fd9b3fd8366fb0e087c7f1e51)

3.5.0
-----
* [Add `Twitter::API#related_results`](https://github.com/sferik/twitter/commit/15fb81202dde3bbf4d64407cb79163095603cdbe)
* [Alias `Twitter::API#status_destroy` to `Twitter::API#tweet_destroy`](https://github.com/sferik/twitter/commit/ec16ed28538b2cf828183999df90da1942b7bcd6)
* [Alias `Twitter::API#status_activity` to `Twitter::API#tweet_activity`](https://github.com/sferik/twitter/commit/ccbdc6776a6780277e6ec813d3ed579f42440631)
* [Move `IdentityMapKeyError` under `Twitter::Error` namespace](https://github.com/sferik/twitter/commit/f1491d2fe1827140ea42b2618d0a25dc03110394)

3.4.1
-----
* [Prevent MultiJson::DecodeError error from bubbling up](https://github.com/sferik/twitter/commit/d870b7b8605e48bb0cd40e4b60684705ec06a846)
* [Add British aliases for "favorite" methods on `Twitter::Status`](https://github.com/sferik/twitter/commit/07b1f410a8865ea3736d53d637fb513b4731a3ec)
* [Correctly handle `nil` response body](https://github.com/sferik/twitter/commit/7fc785fa2ad43187fee2ba4808ffb3d09e8533dc)

3.4.0
-----
* [Refactor retweeted_to and retweeted_by into multiple methods](https://github.com/sferik/twitter/commit/7600cc3d529599cefc8d9c715e5f308ac4ca7319)

3.3.1
-----
* [Fix authentication bug](https://github.com/sferik/twitter/commit/b1fc6eac21293f2f87df9ca6684c30ef8155137f)

3.3.0
-----
* [Refactor `Twitter::RateLimit` class to be non-global](https://github.com/sferik/twitter/commit/6e9da0d0b8ae61e077eb631514922635a78951a7)
* [Combine `Twitter::RateLimit#retry_after` and `Twitter::RateLimit#reset_in` into a single method](https://github.com/sferik/twitter/commit/1702f05a60016013c198626339c57d53031cb17d)
* [Create proper interface for `Twitter::IdentityMap`](https://github.com/sferik/twitter/commit/8996c37a17484dd8ffe0d6a0ab278eb0b4e5e1ca)
* [Move `Twitter::Point` and `Twitter::Polygon` classes under `Twitter::Geo` namespace](https://github.com/sferik/twitter/commit/059cc5545195f99ba1b484e8359b7246f29be37e)
* [Move `Twitter::Photo` class under `Twitter::Media` namespace](https://github.com/sferik/twitter/commit/979ed718c6c31140a5698cbb6c7bd311b799f39e)

3.2.0
-----
* [Make identity map configurable](https://github.com/sferik/twitter/pull/288)
* [Decouple identity map from object instantiation](https://github.com/sferik/twitter/pull/286)
* [Make `IdentityMapKeyError` inherit from `IndexError`](https://github.com/sferik/twitter/commit/5503704c8601fa533299e22b49040cd073b85a6a)
* [Break up `Twitter::User` class into `Twitter::BasicUser`, `Twitter::SourceUser`, `Twitter::TargetUser`, and `Twitter::User`](https://github.com/sferik/twitter/commit/9d4f1e5dc4001adb124d07584f64322555e0e73c)

3.1.0
-----
* [Add size option to `Twitter::User#profile_image_url` and `Twitter::User#profile_image_url_https`](https://github.com/sferik/twitter/commit/bd4c63c327308572f2d4b7ae266216d50ee35beb)
* [Make object equality more strict](https://github.com/sferik/twitter/commit/537a5463d568e9a07ef5de5ce4dcad701b068ff3)
* [Pass options from Twitter::Client.user to Twitter::Client.verify_credentials](https://github.com/sferik/twitter/commit/8d99cfdbc7614690769c1682664cbe8cd9ea9c93)

3.0.0
-----
* [All returned hashes now use `Symbol` keys instead of `String` keys](https://github.com/sferik/twitter/commit/d5b5d8788dc0c0cef6f2c28e6fa2dc6ffcf389eb)
* [`Twitter::Client` methods now allow multiple arguments and return an `Array`](https://github.com/sferik/twitter/commit/78adf3833ebfcafda48d31dee7befdcfa76f2971)
* [`Twitter::Client#users` can now return more than 100 `Twitter::User` objects](https://github.com/sferik/twitter/commit/296a8847aa9bea0881369649a91e38fc2e9b3076)
* [`Twitter::Client#search` now returns a `Twitter::SearchResult` object instead of an array of `Twitter::Status` objects](https://github.com/sferik/twitter/pull/261/files) ([@wjlroe](https://twitter.com/wjlroe))
* [`Twitter::Client#follow` now checks to make sure a user is not already being followed before following](https://github.com/sferik/twitter/commit/24ffbca370f6957bc9a6c43cb6a1ee55cade7bb8)
* [Add `Twitter::Client#follow!` to follow a user without checking whether they are already being followed](https://github.com/sferik/twitter/commit/24ffbca370f6957bc9a6c43cb6a1ee55cade7bb8)
* [Add an identity map](https://github.com/sferik/twitter/commit/218479f71c861db79ccce8e12c4cb59d0a63cc77)
* [Attempt to pull credentials from the environment when not specified](https://github.com/sferik/twitter/commit/32e3fde7ccc7aea15b24159302d7c0fd934a6a0a)
* [Add default timeout options](https://github.com/sferik/twitter/commit/bb8a15d60e930233050e96964823b2f569e0943f)
* [Middleware is now specified as a `Faraday::Builder`](https://github.com/sferik/twitter/commit/2bd5010fc38b235ee9cc09b75e1ae89f23409f94)
* [Faraday errors are now captured and re-raised as a `Twitter::Error::ClientError`](https://github.com/sferik/twitter/commit/ccf3ddeb4cae937fdf3335546c17884472855149)
* [Replace `Twitter::Error.ratelimit` methods with the singleton `Twitter::RateLimit` class](https://github.com/sferik/twitter/commit/4c63a7378305df791b6fbcd3d3beb83ccd360f95)
* [Remove explicit proxy and user agent configuration](https://github.com/sferik/twitter/commit/f6e647f73eaa0f39b4306256789ded414ea9a8c2)
* [Remove untested gateway middleware](https://github.com/sferik/twitter/commit/7e501a99fe15ba9be69d2b791fc1d99c1904542b)
* [Remove deprecated `Twitter::Status#expanded_urls` method](https://github.com/sferik/twitter/commit/50d2613b1ade92c820f553d6e8389a49ec53dac1)

2.5.0
-----
* [Remove `Active Support` dependency](https://github.com/sferik/twitter/compare/v2.4.0...v2.5.0)

2.4.0
-----
* [`Twitter::User` objects can be used interchangeably with user IDs or screen names](https://github.com/sferik/twitter/commit/2dd5d32ca1a67a88d61d2f762e011295cab8a9bd)
* [`Twitter::List` objects can be used interchangeably with list IDs or slugs](https://github.com/sferik/twitter/commit/621e1ee428ea9fea024b26c8775baa47a7c235d9)

2.3.0
-----
* [Merge `Twitter::Client` modules into a monolithic `Twitter::Client` class](https://github.com/sferik/twitter/commit/396bb15fe8a273e01370e6a22efbf1e7f6a7805e)
* [Add `Twitter::Status#full_text`](https://github.com/sferik/twitter/commit/a03eb945df6a58f92cc832f5ffc1c8973c57339e)
* [Add `profile_image_url_https` accessor to `Twitter::Status`](https://github.com/sferik/twitter/commit/5991fa395fcd94bb88e88ed6c9bfae51896978b5) ([@terryjray](https://twitter.com/terryjray))
* [Make `Status#screen_name` return `from_user` attribute and vice versa](https://github.com/sferik/twitter/commit/82afc66a342c51258f80d1ba26959358be1a9c73)
* [Add `created_at` attribute to `Twitter::List`](https://github.com/sferik/twitter/commit/6d408ead1cfa83dd0539fe771495b5f5e594282e)
* [Add ability to pass a user to `Twitter::Client#recommendations`](https://github.com/sferik/twitter/commit/19f5796ba618e634ed56e936eb8f3bcb9822124c)
* [Alias `trends` to `local_trends`](https://github.com/sferik/twitter/commit/b4eb89c33a6b00f9fd685fd7dc95b79ee9e403bb) ([@Tricon](https://twitter.com/Tricon))

2.2.0
-----
* [Don't create a new Faraday instance on every request](https://github.com/sferik/twitter/pull/233/files)
* [Add `Twitter::Mention#source`](https://github.com/sferik/twitter/commit/6829994f4d8ca1e6d444fa75dc78c06bd01a5d74)
* [Add `Twitter::ListMemeberAdded`](https://github.com/sferik/twitter/commit/b40c79d59e8a4cfc71078127542c1f434c3ca517) ([@aamerabbas](https://twitter.com/aamerabbas))
* [Add `entities` attribute to `Twitter::Status`](https://github.com/sferik/twitter/pull/245/files) ([@tomykaira](https://twitter.com/tomykaira))
* [Add `Twitter::Client#list_remove_members`](https://github.com/sferik/twitter/commit/025c5281c9e695ad7fd21bcc34d4df4aaf0f3fb7)

2.1.0
-----
* [Add `in_reply_to_status_id` attribute to `Twitter::Status`](https://github.com/sferik/twitter/commit/9eeb74a5f724681dad1a35b3e052ea78142b532f)
* [Remove `twitter-text` dependency](https://github.com/sferik/twitter/commit/9645fde056353a4fe85a64632ed58f043cfe8871)
* [Add `Twitter::Status#retweeted_status`](https://github.com/sferik/twitter/commit/617ebccb890f612f0cd8883a524d199e838a58a0)
* [Add optional parameter hash to `Twitter::Client#oembed`](https://github.com/sferik/twitter/commit/ce9cf63f84c74d3c0f616524f6674b58e2a45377)
* [Fix `Twitter::Status` object returned by `Twitter::Client#retweet`](https://github.com/sferik/twitter/pull/228/files)
* [Add `from_user_name` and `to_user_name` attributes to `Twitter::Status`](https://github.com/sferik/twitter/commit/d60ac38e4a1623688a5ac8a29b6a4e79295fe9d1)

2.0.0
-----
* Replace `Hashie::Mash` with custom classes and Ruby primitaives
* Any instance method that returns a boolean can now be called with a trailing question mark
* [The `created_at` instance method now returns a `Time` instead of a `String`](https://github.com/sferik/twitter/commit/b92b0ca44af35fc9f72b81690a8aa72fa4bdfbce#diff-5)
* [Replace the `Twitter::Search` class with `Twitter::Client#search`](https://github.com/sferik/twitter/commit/591cbf1be86707584de0548365cc71c795683b2d)
* [Add object equivalence](https://github.com/sferik/twitter/commit/a52e0d2296db55fc0d1dcc184fb6eacba6183642)
* [`Twitter::Client#totals` has been removed. Use `Twitter::Client#user` instead]((https://github.com/sferik/twitter/commit/1ad0928a6232324072e8d960242a99949016cf50)
* [`Twitter.faraday_options` has been renamed to `Twitter.connection_options`](https://github.com/sferik/twitter/commit/221cb650ba126effb3447a3b9e0d58da2bdb507e)
* [All error classes have been moved inside the Twitter::Error namespace](https://github.com/sferik/twitter/commit/1245742f030415ebf5f1054e85fe93bca85cddfb)
* [Remove support for XML response format](https://github.com/sferik/twitter/commit/e60b9cac2b14d11dcc703c87b9a74328c173f35a)
* [Remove all deprecated methods](https://github.com/sferik/twitter/commit/5f59f1935d31df2756fd5bc43ae0f7e57879a5a4)

1.7.2
-----
* [Update multi_xml dependency to 0.4.0](https://github.com/sferik/twitter/commit/01105b7e7f211a140ce61bdbe5e3fc7d68c9b301) ([@masterkain](https://twitter.com/masterkain))
* [Add support for passing options directly to faraday](https://github.com/sferik/twitter/commit/4cc469761ea9e663abaf761e061a89e848ce9beb) ([@icambron](https://twitter.com/icambron))
* [Deprecate Trends#trends_current and remove the XML response format](https://github.com/sferik/twitter/commit/f9f0c1f1ddc5057cdb655f645970f771e1ebc702)

1.7.1
-----
* [Refactor connection and requests to accept options](https://github.com/sferik/twitter/commit/f7570de9f38f57e9fc6f15aa275f308a5ea69bc7) ([@laserlemon](https://twitter.com/laserlemon))
* [Include X-Phx header for internal APIs only](https://github.com/sferik/twitter/compare/f7570de9...34f29fe6) ([@laserlemon](https://twitter.com/laserlemon))

1.7.0
-----
* [Add `Account#totals` and `Account#settings`](https://github.com/sferik/twitter/commit/6496e318ec49f5b054f93a13ea91b4f1d4bb58c0) ([@gazoombo](https://twitter.com/gazoombo))
* [Add `Activity#about_me` and `Activity#by_friends`](https://github.com/sferik/twitter/commit/35e96108c450e76611137feed841f595d7214533)
* [Add `Help#configuration` and `Help#language`](https://github.com/sferik/twitter/commit/a0c88b43990a64b22b82e32301f2b91c094ab721) ([@anno](https://twitter.com/anno))
* [Add `Search#images_facets` and `Search#video_facets`](https://github.com/sferik/twitter/commit/1cc1f3cd75128f5e2c802fe95524a1afffc3962b)
* [Add `Search#search`](https://github.com/sferik/twitter/commit/327724b8edcefaf726d9d92c7e9d8f5380003097)
* [Add `Statuses#media_timeline`](https://github.com/sferik/twitter/commit/f1a78ea183663e9853b4b5dc128dee9ce79391a3)
* [Add `Tweets#update_with_media`](https://github.com/sferik/twitter/commit/cdf717b366a9ac73133a6f576391c4c3f46f9bb3) ([@JulienNakache](https://twitter.com/JulienNakache))
* [Add `Urls#resolve`](https://github.com/sferik/twitter/commit/b8d92b9f3b9669cc7267774b563bae543295350e)
* [Add `User#contributees`](https://github.com/sferik/twitter/commit/2b88f819775b9a90f4969fe03dc66ef1ecc2fb38) ([@GhettoCode](https://twitter.com/GhettoCode))
* [Add `User#contributor`](https://github.com/sferik/twitter/commit/1bb9f2000a322f9026681b78d1e8966409a333a2)
* [Add `User#recommendations`](https://github.com/sferik/twitter/commit/52d13cd4711931539686a483daa15666bae297a5)
* [Add `User#suggest_users`](https://github.com/sferik/twitter/commit/15dc1812f270be0f635f65091044d7cbb88cae4d)
* [Move API version out of endpoint and into path](https://github.com/sferik/twitter/commit/d156fd54a8591b44b22f72890099fce0ce4d58c8)

1.6.2
-----
* [Update hashie dependency to 1.1.0](https://github.com/sferik/twitter/commit/fb86f58203fb7c7dfec30068de663624416e955f)

1.6.1
-----
* [Update faraday dependency to 0.7.0](https://github.com/sferik/twitter/commit/59a50a8f08999fa7a90b0e332171079a137c6752) ([@ngauthier](https://twitter.com/ngauthier))

1.6.0
-----
* [Add a custom OAuth implementation](https://github.com/sferik/twitter/commit/5d2e7cc514b13842d7fe02fa7bc724136ef9f276) ([@NathanielBarnes](https://twitter.com/NathanielBarnes))
* [Unify naming of boolean methods](https://github.com/sferik/twitter/commit/b139e912ef70b55f7af7c03a27346f15ff472c7e)
* [Add convenience method to determine whether a user exists](https://github.com/sferik/twitter/commit/a7fc8616e5733e4c64f98f2ff5562e74e025a1f3)
* [Fully remove `Rash`](https://github.com/sferik/twitter/commit/3b39696902cc05a29bac35e7465ef352264b694d)

1.5.0
-----
* [Change interface to make `Twitter` module behave more like a class](https://github.com/sferik/twitter/commit/df5247de490f7448c35c8f84112a9e7c14ce4057)

1.4.1
-----
* [Update multi_json dependency to version 1.0.0](https://github.com/sferik/twitter/commit/9ab51bc5536e5eebea10283d771cfe57e2fccbc7)

1.4.0
-----
* [Update list methods to use new resources](https://github.com/sferik/twitter/compare/v1.3.0...v1.4.0) ([@erebor](https://twitter.com/erebor))
* [Fix copy/paste bug in `Error#ratelimit_remaining`](https://github.com/sferik/twitter/commit/b74861e75f0cdf7eaafc37162e2f040ae27db002)

1.3.0
-----
* [Update faraday dependency to version 0.6](https://github.com/sferik/twitter/commit/2b29c2109d2ca95a699ebe3822b98091a96256d8)
* [Include response headers when raising an error](https://github.com/sferik/twitter/commit/6db6fe2c2504f566333c6742979436580f5264d4)
* [Fix typo in README for accessing friends and followers](https://github.com/sferik/twitter/commit/2043ab4a6b723cac2a8ed77e26a4b0e3f4f55b03) ([@surfacedamage](https://twitter.com/surfacedamage))

1.2.0
-----
* [Respect global load path](https://github.com/sferik/twitter/commit/6a629a6a06e115388cce6f1de04f45a4b0707cac)
* [Use map and `Hash[]` instead of `inject({})`](https://github.com/sferik/twitter/commit/a2b0b51618f40b526f554c019a6c83b0bf9a8cdf) ([@wtnelson](https://twitter.com/wtnelson))
* [Check headers for `Retry-After` in absence of `retry-after`](https://github.com/sferik/twitter/commit/924253214efcedfeb80b4c6fe57dcbb2a7470177) ([@wtnelson](https://twitter.com/wtnelson))
* [Fix name of `#list_add_members` resource](https://github.com/sferik/twitter/commit/3adcc1592240be2679f0a2c7d0c390b574abe8f1)
* [Don't strip @ signs from screen names](https://github.com/sferik/twitter/commit/38c9dd0a720ea857ff6220b28f66db4c780a7fda)
* [Make `#places_similar` method return a token](https://github.com/sferik/twitter/commit/351e2240717a34d6575a802078077a1681fa4616) ([@nicolassanta](https://twitter.com/nicolassanta))

1.1.2
-----
* [Opt-in for testing with rubygems-test](https://github.com/sferik/twitter/commit/7d92afc138cac1b751b17682fd166b2603f804c6)
* [Add support for `Twitter.respond_to?`](https://github.com/sferik/twitter/commit/ce64c7818f9b62cf91f1fa5dc2e76a9d4205cd2e) ([@fernandezpablo](https://twitter.com/fernandezpablo))

1.1.1
-----
* [Don't set cached `screen_name` when creating a new API client](https://github.com/sferik/twitter/commit/ceeed993b16f95582c648e93de03738362ba1d7b)

1.1.0
-----
* [Overload all methods that require a `screen_name` parameter](https://github.com/sferik/twitter/compare/ecd647e414ac0b0cae96...59cf052ca646a2b79446) ([@gabriel_somoza](https://twitter.com/gabriel_somoza))
* [Rename `user_screen_name` to `screen_name`](https://github.com/sferik/twitter/commit/4fb4f8a28c967f7d5a2cf295b34548a346900cfd) ([@jalada](https://twitter.com/jalada))
* [Handle error returns from lookup](https://github.com/sferik/twitter/commit/0553cdbe262f006fae149309ce51a03985ed8fd2) ([@leshill](https://twitter.com/leshill))
* [Use 'tude' parameter for attitudes](https://github.com/sferik/twitter/commit/8db1bf9dadec3a660a281c94cab2fc335891ce30) ([@ALindeman](https://twitter.com/ALindeman))
* [Add Enumerable mixin to Twitter::Search](https://github.com/sferik/twitter/commit/c175c15d320d10db542ebb4cc13c5f5d583c89c4) ([@ALindeman](https://twitter.com/ALindeman))

1.0.0
-----
* [Fix conditional inclusion of jruby-openssl in Ruby 1.9](https://github.com/sferik/twitter/commit/e8e9b1d7232bf69ac5e217e2e18dc9c8e75f2fc4)
* [Allow users to pass in screen names with leading '@'](https://github.com/sferik/twitter/commit/fc3af84e0d7358ddacf49acefe7d950ac11983e0)
* [UTF-8 encode `Utils` module](https://github.com/sferik/twitter/commit/4a62f181c2ae7b931e17fcfa6532b3a3f0ed0c8e)
* [Copy-edit documentation](https://github.com/sferik/twitter/commit/7873b0306d5fb1f27e4061cd024ab43589441fa4) ([@dianakimball](https://twitter.com/dianakimball))
* [Add methods to `Search` class](https://github.com/sferik/twitter/commit/1871913342a5621edfebb9a7c8be705608e082d5)
* [Changes to `Search` class](https://github.com/sferik/twitter/commit/e769fabc0232cbbcb9d0fa5a07277fb9f50b17c8)
* [Add proxy support](https://github.com/sferik/twitter/commit/1df33b7495093bc1f136d61b8aac9c9038414bc5)
* [Make `#suggestions` method consistent with Twitter API documentation](https://github.com/sferik/twitter/commit/8393a06a9e8ca03be9adffdbfd042c176e2f6597)
* [Rename default user agent](https://github.com/sferik/twitter/commit/2929e533f441bea2313882c4e0ed5593fe999491)
* [Make all global settings overrideable at the class level](https://github.com/sferik/twitter/commit/66f3ac223d6f0822c8b3acd4cdcd8c84c8dacfe0)
* [Expose a property in EnhanceYourCalm for HTTP header "Retry-After"](https://github.com/sferik/twitter/commit/7ab91f9d26351f52d3c803bb191d33bdacff5094) ([@duylam](https://twitter.com/duylam))
* [Merge `Base`, `Geo`, `Trends`, and `Unauthenticated` into `Client` class](https://github.com/sferik/twitter/commit/eb53872249634ee1f0179982b091a1a0fd9c0973) ([@laserlemon](https://twitter.com/laserlemon))
* [Move examples into README](https://github.com/sferik/twitter/commit/96600cb5611965788c41b3788668188d37e16803)
* [Rename `Twitter.scheme` to `Twitter.protocol`](https://github.com/sferik/twitter/commit/512fcdfc22b796d39dd07c2dcc712aa48131d7c6)
* [Map access key/secret names to SimpleOAuth correctly](https://github.com/sferik/twitter/commit/9fa5be3a9e0b7f7dcb4046314d8c6bc41f4f063d)
* [Improved error handling by separating HTTP 4xx errors from HTTP 5xx errors, so HTTP 4xx errors can be parsed first](https://github.com/sferik/twitter/commit/f26e7875980a7b2b16285c31198601b92ac5cbb6)
* [Add tests for XML response format](https://github.com/sferik/twitter/commit/54c4b36b8f9a5a0ad7c741e53409a03a7ddaade7)
* [Switch from httparty to faraday HTTP client library](https://github.com/sferik/twitter/commit/80aff88dae11d64673fe4e025cc8f065a6796345)
* [Switch from oauth to simple_oauth for authentication](https://github.com/sferik/twitter/commit/76cfe3749e56b2b486f2b5ffc9aa7f437cb2db29) ([@laserlemon](https://twitter.com/laserlemon))
* [Handle errors in faraday middleware](https://github.com/sferik/twitter/commit/466a0d9942d1c0c0c35c6302951087076ddf4b82#diff-2)
* [Add #NewTwitter methods and tests](https://github.com/sferik/twitter/commit/0bfbf6352de9bdda2b93ed053a358c0cb8e78e8f)
* [Fix tests that assume position in a `Hash`](https://github.com/sferik/twitter/commit/c9f7ed1d9106807aa6fb27d48a92f4b92d0594a7) ([@duncan](https://twitter.com/duncan))
* [Enable SSL by default (add option to disable SSL)](https://github.com/sferik/twitter/commit/c4f8907d6595f93d63bc84d6575920a14774e656)
* [Use HTTP DELETE method instead of HTTP POST for all destructive methods](https://github.com/sferik/twitter/commit/0bfbf6352de9bdda2b93ed053a358c0cb8e78e8f)
* [Change the method signature for `Base#users` and `Base#friendships` to accept an `Array` and an options `Hash`](https://github.com/sferik/twitter/commit/0bfbf6352de9bdda2b93ed053a358c0cb8e78e8f)
* [Add `Twitter.profile_image` method](https://github.com/sferik/twitter/commit/e6645022aefdc11860fe88b45725a08bb24adf55) ([@ratherchad](https://twitter.com/ratherchad))
* [Improve website style](https://github.com/sferik/twitter/commit/4cdf4e76b6d71d5d4760b46d1a894c00929c0ba3) ([@rodrigo3n](https://twitter.com/rodrigo3n))
* [Make request format configurable](https://github.com/sferik/twitter/commit/d35d6447b25fa84447ae97558958431fa9f6aa29)

0.9.12
------
* [Rename parameters to be less confusing](https://github.com/rorra/twitter/commit/cd7ea8de6663d6ed5ea22b590d39adc72646fc1e) ([@rorra](https://twitter.com/rorra))
* [Update `user` method to match the Twitter API docs](https://github.com/sferik/twitter/commit/cb31e4a26b20d93006d568fab50ccce5c4d1626f) ([@nerdEd](https://twitter.com/nerdEd))
* [Add aliases for search methods](https://github.com/sferik/twitter/commit/05dd3e5a058ef69f874cfe33ae35b01f574e549b)
* [Add `Twitter.user_agent` and `Twitter.user_agent=` methods](https://github.com/sferik/twitter/commit/0fc68f1c52e3b754194fe8a9cfbd9d4499eacbe1)
* [Add `Search#locale` method](https://github.com/sferik/twitter/commit/584bcf9eb896530a87e4122fb1a020c35744f0cf)

0.9.11
------
* [Add a `Search#filter` method](https://github.com/sferik/twitter/commit/0b37998055158d4fed0e3c296d8d2a42ac77d5d9) ([@pjdavis](https://twitter.com/pjdavis))
* [Add test to ensure `Search#fetch` doesn't overwrite `@query(:q)`](https://github.com/sferik/twitter/commit/2e05847cf70692b760c45dd54b6bad820176c9bd) ([@pjdavis](https://twitter.com/pjdavis))
* [Add `Search#retweeted` and `Search#not_retweeted` methods](https://github.com/sferik/twitter/commit/9ef83acdcbe682a8b5a325f89d566f7ef97fffc2) ([@levycarneiro](https://twitter.com/levycarneiro))
* [Switch from YAJL to MultiJson](https://github.com/sferik/twitter/commit/60a7cb179e77319e03c595850119b63fb413a53d) ([@MichaelRykov](https://twitter.com/MichaelRykov))

0.9.10
------
* [Specify Twitter API version for all REST API calls](https://github.com/sferik/twitter/commit/76b1fa31588bbc20166464313027f75e3771e385)
* [Parse all responses with YAJL JSON parser](https://github.com/sferik/twitter/commit/c477f368fde6161dbae59ea7bc7c7d182b15721b)
* [Ensure that users are tested](https://github.com/sferik/twitter/commit/108019e83d745c23ebc92fc8a3f9f8c605b2e884) ([@duncan](https://twitter.com/duncan))
* [Remove redgreen due to Ruby 1.9 incompatibility](https://github.com/sferik/twitter/commit/83e1ea168da2e38c3f393972bf1d8eb665df2510) ([@duncan](https://twitter.com/duncan))
* [Make all tests pass in Ruby 1.9](https://github.com/sferik/twitter/commit/7bead60774fb118ef63fb1557976194848af6754) ([@duncan](https://twitter.com/duncan))

0.9.9
-----
* [Bump dependency versions](https://github.com/sferik/twitter/commit/ac8114c1f6ba2da20c2267d3133252c2ffc6b6a3)
* [Remove Basic Auth](https://github.com/sferik/twitter/pull/56) ([@rodrigo3n](https://twitter.com/rodrigo3n))
* [Flatten `ids_or_usernames` before iterating](https://github.com/sferik/twitter/commit/956fb23f82cc1f91f6beefb24cf052cf48475a3f) ([@jacqui](https://twitter.com/jacqui))
* [Add an example to list followers and friends sorted by followers count](https://github.com/sferik/twitter/commit/fb57b27e8a48abcc82810fe476413e8b506cebe6) ([@danicuki](https://twitter.com/danicuki))
* [Add optional query parameter to `list_subscribers`](https://github.com/sferik/twitter/commit/a608d4088edf8772a3549326bed1124c9a2a123d)
* [Change trends endpoint to api.twitter.com/1/trends](https://github.com/sferik/twitter/commit/39ff888b243ba57098589d4e304dd6dec877d05f)
* [Use Bundler](https://github.com/sferik/twitter/commit/ebcb1d2c76d45f691cc90c880d13d19bc69a6f32)

0.9.8
-----
* [Geo API](https://github.com/sferik/twitter/commit/0e5aa205f9e29db434d84452f59694d9b64877d2) ([@anno](https://twitter.com/anno))
* [Set `api_endpoint` for unauthenticated calls](https://github.com/sferik/twitter/commit/ff20ecb4f4fef12c58572fb31e5c06162f8659d7) ([@earth2marsh](https://twitter.com/earth2marsh))

0.9.7
-----
* [Add `api_endpoint` option for Search](https://github.com/sferik/twitter/commit/3c3d73fb8eedb5d322aeb1e4431d9936226fef9b)

0.9.6
-----
* [Deprecated Basic Auth](https://github.com/sferik/twitter/commit/878c09527037ab8ec5ac11a48afece61f03861e1)
* [Add `api_endpoint` option for OAuth](https://github.com/sferik/twitter/commit/be937cf93db35f60cd47288aeea45afd2ab42288)

0.9.5
-----
* [Saved searches](https://github.com/sferik/twitter/commit/d5f0b5846b24468f323cc4f96e583fd267240615) ([@zmoazeni](https://twitter.com/zmoazeni))
* [Handle null result sets in search more gracefully](https://github.com/sferik/twitter/commit/f6d1f995dc7757dda4f4ac71dda2487d56d51c85) ([@sferik](https://twitter.com/sferik))
* [Add `report_spam`](https://github.com/sferik/twitter/commit/91275b549ebdd1cad795dff9f7a1772a4ca37749) ([@chrisrbailey](https://twitter.com/chrisrbailey))
* [Tests for `friendship_exists?` method](https://github.com/sferik/twitter/commit/e778d7f5f2bed73428c854d5d788d4a2d58540cd) ([@sferik](https://twitter.com/sferik))
* [Replace JSON parser with YAJL JSON parser](https://github.com/sferik/twitter/commit/1f480a85925025aec1ac5c91cfb45b4e74e4c9c3) ([@sferik](https://twitter.com/sferik))
* [Cursors for lists](https://github.com/sferik/twitter/commit/d283cefdbcaeee6005b0ec747e8d6bded14911b2) ([@zmoazeni](https://twitter.com/zmoazeni))

0.9.4
-----
* [Rolled back search API endpoint to get around rate limiting issues](https://github.com/sferik/twitter/commit/f9c7af99b4560f39b3542582934ae07955b6c9cc) ([@secobarbital](https://twitter.com/secobarbital))

0.9.3
-----
* [Restore Ruby 1.8.6 compatibility](https://github.com/sferik/twitter/commit/b725b1b8a105fa3488783cef43b7db8b0dbb7c99) ([@raykrueger](https://twitter.com/raykrueger))

0.9.2
-----
* [Make error handling consistent between authenticated and unauthenticated method calls](https://github.com/sferik/twitter/commit/f62a1502ba9c4a764d25a4179982fabd3bff2210) ([@sferik](https://twitter.com/sferik))
* [Test error handling for unauthenticated methods](https://github.com/sferik/twitter/commit/4de5c9212142ceb0206f979755e6e151280b16b9) ([@sferik](https://twitter.com/sferik))

0.9.1
-----
* [Add cursor to `lists` method](https://github.com/sferik/twitter/commit/a16ad354be4fae3d3f86207d8c5ae8b4c2a11b52) ([@sferik](https://twitter.com/sferik))
* [Add Twitter API version to trends method calls](https://github.com/sferik/twitter/commit/6f23c5eb3ffdac6eac65fa2b6d36f08aa7b6e1fb) ([@sferik](https://twitter.com/sferik))
* [Add Twitter API version to unauthenticated method calls](https://github.com/sferik/twitter/commit/fb895cc7e645499826dcc96e2cf8727c94eac83f) ([@sferik](https://twitter.com/sferik))
* [Remove rubygems dependencies](https://github.com/sferik/twitter/commit/0f7a9ee4a1aee45bfb7136a0f6f48f9b7632e663) ([@sferik](https://twitter.com/sferik))

0.9.0
-----
* [Add `Base#retweeters_of` method](https://github.com/sferik/twitter/commit/7de2d6204028b6741ce7a72b12efe868e074331c)
* [Add `result_type` to search for popular/recent results](https://github.com/sferik/twitter/commit/c32fa818f8331a7ff02f04f6cba8739423902029)
* [Add `users` method for bulk user lookup](https://github.com/sferik/twitter/commit/5723b60f042d98b630040fa076ac86e9b735dee8) ([@sferik](https://twitter.com/sferik))
* [Add Twitter API version to authenticated method calls](https://github.com/sferik/twitter/commit/69d4df515fe95f727221dad19b92665dc24f06d0) ([@sferik](https://twitter.com/sferik))
* [Search exclusions](https://github.com/sferik/twitter/commit/cb05e77adb2d771170d731ad2e55ba17bcb13766) ([@abozanich](https://twitter.com/abozanich))

0.8.6
-----
* [Bump httparty version](https://github.com/sferik/twitter/commit/643517da3d12442883d90918b280e968809a4750) ([@dewski](https://twitter.com/dewski))

0.8.5
-----
* [Add `Search#next_page?` and `Search#fetch_next_page` methods](https://github.com/sferik/twitter/commit/767ddaa62e8fa9e3872ddd17323f323d9f1393e4) ([@cyu](https://twitter.com/cyu))

0.8.4
-----
* [Add `query` parameter to `membership` method](https://github.com/sferik/twitter/commit/f09b3121d4c721c34f40a11580a7a1d4ffc0df22) ([@mingyeow](https://twitter.com/mingyeow))
* [Add `Search#phrase` method](https://github.com/sferik/twitter/commit/e3e8f7e4b1ea8a315f935805e409a3fff6a5483d) ([@zagari](https://twitter.com/zagari))
* [Add `Trends#available` and `Trends#location` methods](https://github.com/sferik/twitter/commit/39b8d8dd3bb25cb5cd081cae23486fb47c25ec8f)

0.8.3
-----
* [Add `Twitter.list_timeline` method](https://github.com/sferik/twitter/commit/aed3a298b613a508bb9caf93afc7f12c50626ad7) ([@spastorino](https://twitter.com/spastorino))

0.8.2
-----
* [Add `Base#update_profile_image` method](https://github.com/sferik/twitter/commit/10afe76daef3a2b8e10917b9550724cc9c3a6c19) ([@urajat](https://twitter.com/urajat))

0.8.1
-----
* [Add `Twitter.timeline` method](https://github.com/sferik/twitter/commit/dc26a0c9b5a6a98aec4ca9c0a48333e665c9bf18)

0.8.0
-----
* [Make API endpoint configurable to use services like Tumblr](https://github.com/sferik/twitter/commit/c5550f1317538638b754d6b0dbbb372e069b5580)

0.7.11
------
* [Add list timeline paging](https://github.com/sferik/twitter/commit/591d31a45b1a360d5743d2bf3966e7e9b563b9b7) ([@kchen1](https://twitter.com/kchen1))

0.7.10
------
* [Add `Base#blocks` and `Base#blocking` methods](https://github.com/sferik/twitter/commit/0eb099001f060431c56c1884d86abb2e53a09c6d)

0.7.9
-----
* [Add `Base#retweets` method](https://github.com/sferik/twitter/commit/a1a834575000bbb8fb430632b6bf88e19daeb8fb) ([@ivey](https://twitter.com/ivey))

0.7.8
-----
* [Use `cursor` parameter to `list_members` method](https://github.com/sferik/twitter/commit/9f393f05c127623f4c58a68e2246a3553f225349) ([@ivey](https://twitter.com/ivey))

0.7.7
-----
* [Fix bug in `list_remove_member` when using OAuth](https://github.com/sferik/twitter/commit/b20b770af3d6594f8e551cade3cfbd58a0647c2d)
* [Bump oauth dependency to version 0.3.6](https://github.com/sferik/twitter/commit/3eeed693180d15ba4ca2370c41bd5547f715fc88)
* [Add `Base#update_profile_background` method](https://github.com/sferik/twitter/commit/3eeed693180d15ba4ca2370c41bd5547f715fc88) ([@kev_in](https://twitter.com/kev_in))
* [Add `Base#blocked_ids` method](https://github.com/sferik/twitter/commit/2a5046500eb30141f55552d9b151857d08a1436a) ([@rizwanreza](https://twitter.com/rizwanreza))
* [Add `Search#since_date` and `Search#until_date` methods](https://github.com/sferik/twitter/commit/9dcd340817224fa34fcb515f79a846886ffa1427) ([@jschairb](https://twitter.com/jschairb))

0.7.6
-----
* [Add `Base#home_timeline` method](https://github.com/sferik/twitter/commit/2de3786e75e6a1725572d3f08f6886f64e507851) ([@coderifous](https://twitter.com/coderifous))

0.7.5
-----
* [Use Hashie instead of Mash to avoid conflicts with extlib](https://github.com/sferik/twitter/commit/365f8378b45c93ed6219ac49afec5c7f7eb85fe6) ([@hassox](https://twitter.com/hassox))

0.7.4
-----
* [Support for user search](https://github.com/sferik/twitter/commit/54e046924431a08e3dfce06f571f71ebb76f7bbd)

0.7.3
-----
* [Add `Base#list_subscriptions` method](https://github.com/sferik/twitter/commit/2273c8a4e7c5d496922fc34551b46b22d30b68aa) ([@christospappas](https://twitter.com/christospappas))

0.7.2
-----
* [Add `Base#friendship_show` method](https://github.com/sferik/twitter/commit/693f95a6a19dd51c047078ef969e14357930bcd7) ([@dcrec1](https://twitter.com/dcrec1))

0.7.1
-----
* [Bump dependency versions](https://github.com/sferik/twitter/commit/d6bf8c5693f0ec4eedd641b97a7e6f0fdce75e2c)

0.7.0
-----
* [Add support for lists](https://github.com/sferik/twitter/commit/be4bffd79c2bdcfd2988ef6a65cbca8a8f6abd6d)

0.6.14
------
* [Lower oauth dependency to version 0.3.4 as people are complaining about 0.3.5](https://github.com/sferik/twitter/commit/dd144c377bc888388099e029a0e1505a66392bb1)

0.6.13
------
* [Bump oauth dependency to version >= 0.3.5](https://github.com/sferik/twitter/commit/555ae1fc13146b74b8df0346caea1a6b065b344f)

0.6.12
------
* [Fix `fakeweb` test issue](https://github.com/sferik/twitter/commit/cdd9dba19f6edc21f1b7eefb66db133dec682423) ([@obie](https://twitter.com/obie))
* [Add `Search#user_agent` method](https://github.com/sferik/twitter/commit/e8fbad6a9cfdcfaad4938f7243fc971a1ea8ac8c)

0.6.11
------
* [Add the ability to sign in with Twitter instead of authorizing](https://github.com/sferik/twitter/commit/68b6252a21e7e773d108027f693b8378593e21ad)

0.6.10
------
* [Add `Trends#current`](https://github.com/sferik/twitter/commit/549f34903be38232c24044d9972629a86a0503a4), [`Trends#daily`, and `Trends#weekly` methods](https://github.com/sferik/twitter/commit/dc8046aea5794303f6f36622221a412a4e80f9a8)

0.6.9
-----
* [Bump oauth dependency to version 0.3.4](https://github.com/sferik/twitter/commit/88d4612b50d2be7cc300120278d53c80265e8780)

0.6.8
-----
* [Fix httparty dependency](https://github.com/sferik/twitter/commit/44aa418a22233c84cea1dae74b158cd490589b10)

0.6.7
-----
* [Bump httparty dependency to version 0.4.3 which allows `response.message` and fixes errors that the lack of `response.message` was causing](https://github.com/sferik/twitter/commit/a630b1c77792641794745d2f3cbba6c64d168d62)

0.6.6
-----
* [Add `query` parameter to `user` method](https://github.com/sferik/twitter/commit/33ae7dbd7593235efb8ea1df13638891b621244f)
* [Add `ssl` optional parameter to use HTTPS instead of HTTP for `HTTPAuth`](https://github.com/sferik/twitter/commit/f46cdf9ce957b03539bd4dc76a83ce439535d349)
* [Add `Twitter.status`, `Twitter.friend_ids`, and `Twitter.follower_ids` methods](https://github.com/sferik/twitter/commit/55813617c5b4cf672800bf7f9e7473904e3c3194)

0.6.5
-----
* [Fix `friend_ids` and `follower_ids` bombing on mashing](https://github.com/sferik/twitter/commit/f01c2878033cd6afc1e718f2140c82b9708e5603)

0.6.4
-----
* [More explicit about dependency versions in gemspec and when requiring](https://github.com/sferik/twitter/commit/5ce3eeb25c5b8bcd8caa8704c5d125174781781d)

0.6.3
-----
* [Add `Twitter.user` method](https://github.com/sferik/twitter/commit/cb46975eaa8aa7e02ad798ba8b7b62017f15604c)

0.6.2
-----
* [Add `Search#max` method](https://github.com/sferik/twitter/commit/e79cc1fdb306da24462c6617b118e03ccbead9f1)

0.6.1
-----
* [Rename one of the two `friend_ids` methods to `follower_ids`](https://github.com/sferik/twitter/commit/051d19db49dce2422d06181c5a3b595e3a9b85b3)

0.6.0
-----
* [Add HTTP authentication](https://github.com/sferik/twitter/commit/d713ecfbe80edde688009fa6bfbf32a2de687a39)

0.5.3
-----
* [Only send `follow` parameter to Twitter if `follow` is true for calls to `friendship_create`](https://github.com/sferik/twitter/commit/5ebf39c0538a3dfd48c6a1dbdf8558305737ce69)

0.5.2
-----
* [Add mash as an install dependency](https://github.com/sferik/twitter/commit/a8693b27791e966736415cb90335600d075f60dd)
* [Add options to `search`](https://github.com/sferik/twitter/commit/096d56ed9a62a0ea53bfe3a8df588ddef71df1c9)
* [Add missing variables in exception raising](https://github.com/sferik/twitter/commit/e21a4f69c68d28148045e7c98ce1841d72994e1e)
* [Add development dependencies to `Rakefile` to make that more explicit](https://github.com/sferik/twitter/commit/de57b1c2834653ea4c336ed426ee8fbbebcd80b2) ([@technomancy](https://twitter.com/technomancy))
* [Add workaround for `Mash#hash` that allows using return objects in sets and such](https://github.com/sferik/twitter/commit/2da491308766e82c797c7801bdc3a440b7f8d719) ([@technomancy](https://twitter.com/technomancy))

0.5.1
-----
* [Add data error hash returned from Twitter to a few of the exceptions to help with debugging](https://github.com/sferik/twitter/commit/72d46c4804a30b28ab351a5a0d37d6bc664e577e)
* [Fix bug with `friendship_exists?` throwing a stringify keys error because it was returning `true` or `false` instead of a `Hash` or `Array`](https://github.com/sferik/twitter/commit/1e9def65277125f23739be034abd4059a42d2b87)

0.5.0
-----
* [Proxy no longer supported (someone please add it back in, I never use proxies)](https://github.com/sferik/twitter/commit/dd2445e3e2c97f38b28a3f32ea902536b3897adf)
* [Identica support killed with an axe (nothing against them but I don't use it)](https://github.com/sferik/twitter/commit/dd2445e3e2c97f38b28a3f32ea902536b3897adf)
* [CLI shot to death (will be reborn at a later date using OAuth and its own gem)](https://github.com/sferik/twitter/commit/dd2445e3e2c97f38b28a3f32ea902536b3897adf)

0.4.3
-----
* [Make `verify_credentials` return a `Twitter::User` rather than a Hpricot doc](https://github.com/sferik/twitter/commit/6a8efc464dcb174e41b2eb0197a79e778dae1428)

0.4.2
-----
* [Add `Base#friend_ids` and `Base#follower_ids` methods](https://github.com/sferik/twitter/commit/b70718cc31684af6ce2d1c2a11adaaba29ea7b92) ([@joshowens](https://twitter.com/joshowens))

0.4.1
-----
* [Add better exception handling](https://github.com/sferik/twitter/commit/2b85bed874902d184e5d53c0a0bd249fd1ed3b8b) ([@billymeltdown](https://twitter.com/billymeltdown))
* [Add `Search#page` method](https://github.com/sferik/twitter/commit/977023126fbe7fdf13af53d840ca3b6807cd2d85) ([@ivey](https://twitter.com/ivey))
* [Add an option to display tweets on CLI in reverse chronological order](https://github.com/sferik/twitter/commit/40d2f1ae631dce3c31c6a13d295989e945b22622) ([@coderdaddy](https://twitter.com/coderdaddy))
* [Add `in_reply_to_status_id` option for replying to statuses](https://github.com/sferik/twitter/commit/2ecceda9fa74d486e3ba62edba7fa42a443191fa) ([@anthonycrumley](https://twitter.com/anthonycrumley))
* [Fix a bug where the [@config was improperly set](https://github.com/sferik/twitter/commit/9c5fd0f0a0186638aae189e28a3a0d0d20e7d3d5) ([@pope](https://twitter.com/pope))
* [Fix `verify_credentials` to include a format](https://github.com/sferik/twitter/commit/bf6f783e8867148a056d130f00a03679ea9b414b) ([@dlsspy](https://twitter.com/dlsspy))

0.4.0
-----
* [Remove Active Support dependency and switched to echoe for gem management](https://github.com/sferik/twitter/commit/fbb792561ea2aba8c8e7abb946d2a5e6e3d64fb0)
* [Remove CLI dependencies](https://github.com/sferik/twitter/commit/906d34db1a81314bb8929d9b5ee61519ed6dc080)

0.3.7
-----
* [Fix `source` parameter not getting through](https://github.com/sferik/twitter/commit/e3743cf22df3ad9406bf8c2e4425f30680606283)

0.3.6
-----
* [Refactor the remaining methods that were not using `request` to use it](https://github.com/sferik/twitter/commit/8a802c4b461be0d4d7f374888591a9af6ef8b8d2)

0.3.5
-----
* [Remove sqlite-ruby dependency](https://github.com/sferik/twitter/commit/9277e832daf9539e70f446b8b4f7093d8eb98484)

0.3.4
-----
* [Add `Search` class](https://github.com/sferik/twitter/commit/538a5d4b1a72ed2bf97404704699f498ab082ca9)

0.3.3
-----
* [Add Identica support](https://github.com/sferik/twitter/commit/ed06aaf27eea8852198200eb3db510d56508e727) ([@dlsspy](https://twitter.com/dlsspy))
* [Update methods to `POST` instead of `GET`](https://github.com/sferik/twitter/commit/ed06aaf27eea8852198200eb3db510d56508e727)

0.3.2
-----
* [Add the CLI gems as dependencies until it is separated from the API wrapper](https://github.com/sferik/twitter/commit/52af6fd83bb2e72b90abd6114e264a88431cfb34)
* [Add cleaner CLI errors for no active account or no accounts at all](https://github.com/sferik/twitter/commit/dbc9e57d0a66ee585893b0b5955078575effc616)
* [Add `username` and `password` parameters to `add` method](https://github.com/sferik/twitter/commit/013b48229786c1080ee79a490e731f4b1811a7e4)

0.3.1
-----
* [Add `open` method to CLI](https://github.com/sferik/twitter/commit/84e77a1d515f762d7a24f697786f5959d4f1cc2e)
* [Add `-f` option to timeline and replies which ignores the `since_id` and shows all results](https://github.com/sferik/twitter/commit/84e77a1d515f762d7a24f697786f5959d4f1cc2e)
* [Add `clear_config` to remove all cached values](https://github.com/sferik/twitter/commit/84e77a1d515f762d7a24f697786f5959d4f1cc2e)
* [Improved the output of `timelines` and `replies`](https://github.com/sferik/twitter/commit/84e77a1d515f762d7a24f697786f5959d4f1cc2e)

0.3.0
-----
* [Support multiple accounts in CLI and switching between them](https://github.com/sferik/twitter/commit/35eddef783492990bf0bebcae1f5891a556988e4)
* [Make `d` method accept stdin](https://github.com/sferik/twitter/commit/25ddfe33a10a252ff7d9ba74d4d16e3e25719661)
* [Add `Status#source`, `Status#truncated`, `Status#in_reply_to_status_id`, `Status#in_reply_to_user_id`, `Status#favorited`, and `User#protected` methods](https://github.com/sferik/twitter/commit/d02d233000667c74101571f9362532a57715ae4e)
* [Add `Base#friendship_exists?`, `Base#update_location`, `Base#update_delivery_device`, `Base#favorites`, `Base#create_favorite`, `Base#destroy_favorite`, `Base#block`, and `Base#unblock` methods](https://github.com/sferik/twitter/commit/eeca67c5693dc175cf1990c2657a6efd8c4cbd6d)
* [Rewrite methods that had `since` or `lite` parameters to use a `Hash`](https://github.com/sferik/twitter/commit/eeca67c5693dc175cf1990c2657a6efd8c4cbd6d)

0.2.7
-----
* [Add `Base#rate_limit_status` method](https://github.com/sferik/twitter/commit/2b5325b1875574805fde77f30d0df84e423272e5) ([@danielmorrison](https://twitter.com/danielmorrison))
* [Add `source` parameter to `Base#post`](https://github.com/sferik/twitter/commit/215b2ca687014e042f991192281ea1dfbe100665)
* [Add `twittergem` as the source when posting from the command-line interface](https://github.com/sferik/twitter/commit/d94b6bdb23dd27ff25cf170cd7ceb5610187d176)
* [Raise `Twitter::RateExceeded` when you hit your limit](https://github.com/sferik/twitter/commit/d94b6bdb23dd27ff25cf170cd7ceb5610187d176) ([@jimoleary](https://twitter.com/jimoleary))
* [Raise `Twitter::Unavailable` when Twitter returns 503](https://github.com/sferik/twitter/commit/d94b6bdb23dd27ff25cf170cd7ceb5610187d176)
* [Make `Twitter::CantConnect` messages more descriptive](https://github.com/sferik/twitter/commit/d94b6bdb23dd27ff25cf170cd7ceb5610187d176)
* [Make quoting your message optional when posting from the command-line interface](https://github.com/sferik/twitter/commit/d94b6bdb23dd27ff25cf170cd7ceb5610187d176) ([@bcaccinolo](https://twitter.com/bcaccinolo))
* [Alias `post` to `p` on the command-line interface](https://github.com/sferik/twitter/commit/d94b6bdb23dd27ff25cf170cd7ceb5610187d176) ([@bcaccinolo](https://twitter.com/bcaccinolo))
* [Unescape HTML and add color to the command-line interface](https://github.com/sferik/twitter/commit/d94b6bdb23dd27ff25cf170cd7ceb5610187d176) ([@mileszs](https://twitter.com/mileszs))
* [Add gemspec](https://github.com/sferik/twitter/commit/d94b6bdb23dd27ff25cf170cd7ceb5610187d176) ([@technoweenie](https://twitter.com/technoweenie), [@mileszs(https://twitter.com/mileszs))
* [Fix stack trace error on first command-line operation](https://github.com/sferik/twitter/commit/d94b6bdb23dd27ff25cf170cd7ceb5610187d176) ([@mrose2n](https://twitter.com/mrose2n))

0.2.6
-----
* [Found a simpler way of doing `stdin` without any extra gem dependencies](https://github.com/sferik/twitter/commit/2ef6c3e7280b64d5d4a956ca245e631b126001b0)

0.2.5
-----
* [Command-line interface can use `stdin` for posting](https://github.com/sferik/twitter/commit/d4e710bd3184f33775bf969b0993cbc9dff0ed50) ([@reclusive_geek](https://twitter.com/reclusive_geek))
        $ twitter post 'test without stdin' # => twitters: test without stdin
        $ echo 'test with stdin' | twitter post 'and an argv(1)' # => twitters: test with stdin and an argv(1)
        $ echo 'test with stdin without any argv(1)' | twitter post # => twitters: test with stdin without any argv(1)

0.2.4
-----
* [Add `lite` parameter to `friends` and `followers` methods, which doesn't include the user's current status](https://github.com/sferik/twitter/commit/0de3901258de5b2a4a3fda308e495ee373d07ea6) ([@danielmorrison](https://twitter.com/danielmorrison))
* [Update `since` parameter to use HTTP header](https://github.com/sferik/twitter/commit/90b5b5ebb2a7d94a278e3ff374e4fde4cf850234) ([@danielmorrison](https://twitter.com/danielmorrison))
* [Add `since` parameter on `timeline` and `replies` methods](https://github.com/sferik/twitter/commit/90b5b5ebb2a7d94a278e3ff374e4fde4cf850234) ([@danielmorrison](https://twitter.com/danielmorrison))

0.2.3
-----
* [Add `d` to the command-line interface](https://github.com/sferik/twitter/commit/a9ecddd3323ef202248dae59d049b00b88b76b4e) ([@humbucker](https://twitter.com/humbucker))
* [Add progress dots while waiting for confirmation when Twitter is being slow](https://github.com/sferik/twitter/commit/02a24d9042f3fa0235759fbbd6f34ea639a01578) ([@HendyIrawan](https://twitter.com/HendyIrawan))

0.2.2
-----
* [Add `Base#leave` and `Base#follow` methods](https://github.com/sferik/twitter/commit/4878689063574ad88ea76343387094fc634ccead)

0.2.1
-----

0.2.0
-----
* [Alias `direct_messages` to `received_messages`](https://github.com/sferik/twitter/commit/c2d8c55516747627452224af8faecc15ee6b5fd4)
* [Add `Base#sent_messages`, `Base#create_friendship`, `Base#destroy_friendship`, `Base#featured`, `Base#replies`, `Base#destroy`, and `Base#status` methods](https://github.com/sferik/twitter/commit/c2d8c55516747627452224af8faecc15ee6b5fd4)
* [Add Active Support dependency](https://github.com/sferik/twitter/commit/c2d8c55516747627452224af8faecc15ee6b5fd4)
* [Add `Base#d` method](https://github.com/sferik/twitter/commit/139a820de0bcc97ece7e33435535985555231bc8) ([@jnewland](https://twitter.com/jnewland))
* [Fix `since` parameter in `Base#direct_messages` method](https://github.com/sferik/twitter/commit/41a9006be9221d7305752639ac4440b3a8859cd0) ([@jnewland](https://twitter.com/jnewland))

0.1.1
-----
* [Add support for Hpricot 0.5+](https://github.com/sferik/twitter/commit/4aa2fabaa62c60e9f11f29510db10b6ed406e510) ([@erebor](https://twitter.com/erebor))

0.1.0
-----
* [Add `Base#d` method](https://github.com/sferik/twitter/commit/13e031f8d2e8db6ca8ace18a25886fb690d580d2)
* [Add `Base#direct_messages` method](https://github.com/sferik/twitter/commit/0f4d699a5310dc8a4e2997b82853f5466292b320)
* [Add `Base#featured` and `Base#friends_for` methods](https://github.com/sferik/twitter/commit/21ca95ffa3f42aaf7728c3d5c2aa5f1f9ed84fe7)
* [Add tests](https://github.com/sferik/twitter/commit/ff1ae65766109c75f80c4b15797e12a69d7c29ad)
* [Remove `relative_created_at`](https://github.com/sferik/twitter/commit/ff1ae65766109c75f80c4b15797e12a69d7c29ad)

0.0.5
-----
* [Code cleanup](https://github.com/sferik/twitter/commit/abd6eb31089975e3dc65f7e0bb4156feacc97a1c)

0.0.4
-----
* [Add `User#location`, `User#description`, `User#url`, and `User#profile_image_url` methods](https://github.com/sferik/twitter/commit/e6737ec8b07b9fd1ffd96a21074a100a6fb3cf7e) ([@al3x](https://twitter.com/al3x))

0.0.3
-----
* [Make error message more informative](https://github.com/sferik/twitter/commit/1763cd85c4fd85cde6815cc7c1b74937dd7aeeaf)

0.0.2
-----
* Add command-line options for `friend` and `follower`
* Improved docs

0.0.1
-----
* [Initial release](https://github.com/sferik/twitter/commit/cd7aecde450157ae2ec0c07a2171d7149bebb74a)

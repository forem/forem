module Events
  module Billboards
    class LiveStream
      attr_reader :event

      def initialize(event)
        @event = event
      end

      def feed_html
        start_hour = event.start_time.in_time_zone("America/New_York").hour
        start_min = event.start_time.in_time_zone("America/New_York").min

        <<~HTML
          <style>
            .overlay-feed {
              width: 100%;
              height: 51vw;
              background: #000;
              color: #fff;
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              font-family: sans-serif;
              font-size: calc(1rem + 1vw);
              border-radius: 12px;
              margin-bottom: 20px !important;
            }
            .overlay-feed.hidden {
              display: none;
            }
            .player-container-feed iframe {
              width: 100%;
              height: 51vw;
              border: none;
              border-radius: 12px;
              margin-bottom: 20px !important;
            }
            @media (min-width: 768px) {
              .overlay-feed, .player-container-feed iframe {
                height: 340px;
              }
            }
          </style>
      
          <h1 style="font-size:calc(18px + 0.75vw);margin: 25px auto;margin-top:15px !important">
            #{event.title}
          </h1>
      
          <div class="overlay-feed" id="overlay-feed-#{event.id}">
            <div>Stream starts in…</div>
            <div id="countdown-feed-#{event.id}">--:--:--</div>
          </div>
          <div class="player-container-feed" id="player-container-feed-#{event.id}"></div>
      
          <p style="opacity:0.9;margin-bottom:12px;font-size:calc(1em + 0.1vw);">
            #{event.description}
          </p>
      
          <p style="margin-bottom:15px">
            <a
              href="#{link}"
              class="ltag_cta ltag_cta--branded"
              role="button"
              style="font-weight:bold;border-width:2px;width:100%;padding:15px 2px;text-align:center !important;font-size:calc(16px + 0.6vw);display:block"
            >
              Tune in to the full event
            </a>
          </p>
      
          <p style="font-size:0.9em;opacity:0.8;margin-bottom:8px;font-style:italic">
            #{Settings::Community.community_name} is partnering to bring live events to the community. Join us or dismiss this billboard if you're not interested. ❤️
          </p>
          
          <script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.29.1/moment.min.js"></script>
          <script src="https://cdnjs.cloudflare.com/ajax/libs/moment-timezone/0.5.33/moment-timezone-with-data.min.js"></script>
          <script>
            (function() {
              const START_HOUR = #{start_hour};
              const START_MINUTE = #{start_min};
              const IFRAME_SRC = "#{event.primary_stream_url}";

              function getTargetMoment() {
                const nowNY = moment.tz("America/New_York");
                return nowNY.clone().hour(START_HOUR).minute(START_MINUTE).second(0).millisecond(0);
              }

              const overlay = document.getElementById("overlay-feed-#{event.id}");
              const countdownEl = document.getElementById("countdown-feed-#{event.id}");
              const playerContainer = document.getElementById("player-container-feed-#{event.id}");
              let timerId;

              function update() {
                const nowNY = moment.tz("America/New_York");
                const target = getTargetMoment();

                if (nowNY.isSameOrAfter(target)) {
                  clearInterval(timerId);
                  if (overlay) overlay.classList.add("hidden");

                  if (playerContainer && !playerContainer.querySelector("iframe")) {
                    const iframe = document.createElement("iframe");
                    iframe.src = IFRAME_SRC;
                    iframe.allowFullscreen = true;
                    playerContainer.appendChild(iframe);
                  }
                  return;
                }

                if (countdownEl) {
                  const diff = moment.duration(target.diff(nowNY));
                  const hours = String(Math.floor(diff.asHours())).padStart(2, "0");
                  const minutes = String(diff.minutes()).padStart(2, "0");
                  const seconds = String(diff.seconds()).padStart(2, "0");
                  countdownEl.textContent = `${hours}:${minutes}:${seconds}`;
                }
              }

              timerId = setInterval(update, 1000);
              update();
            })();
          </script>
        HTML
      end

      def post_html
        start_hour = event.start_time.in_time_zone("America/New_York").hour
        start_min = event.start_time.in_time_zone("America/New_York").min

        <<~HTML
          <style>
            .bb-grid-container {
              display: grid;
              gap: 25px;
              grid-template-columns: 1fr;
              width: 100%;
            }
            .bb-grid-item--first {
              display: none;
            }
            @media (min-width: 1280px) {
              .popover-billboard .text-styles {
                font-size: 1.22em;
              }
            }
            .crayons-bb__title {
              color: var(--label-secondary);
              font-size: var(--fs-s);
              line-height: var(--lh-base);
              margin-left: var(--su-1);
              align-self: center;
            }
            .crayons-bb__header {
              width: 100%;
              display: flex;
              align-items: center;
            }
            
            .overlay-post {
              width: 100%;
              height: 100%;
              min-height: 200px;
              background: #000;
              color: #fff;
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              font-family: sans-serif;
              font-size: calc(1rem + 1vw);
              border-radius: 12px;
              margin-bottom: 20px !important;
            }
            .overlay-post.hidden {
              display: none;
            }
            .player-container-post iframe {
              width: 100%;
              height: 100%;
              min-height: 200px;
              border: none;
              border-radius: 12px;
              margin-bottom: 20px !important;
            }
            
            @media (min-width: 768px) {
              .overlay-post, .player-container-post iframe {
                height: 340px;
              }
              .bb-grid-container {
                grid-template-columns: 1fr 1fr;
              }
              .bb-grid-item--first {
                display: block;
              }
            }
            @media (min-width: 1000px) {
              .crayons-card[data-id="93431"] {
                padding-left: 8px !important;
              }
            }
          </style>
      
          <div class="bb-grid-container">
            <div class="bb-grid-item bb-grid-item--first">
              <div class="overlay-post" id="overlay-post-#{event.id}">
                <div>Stream starts in…</div>
                <div id="countdown-post-#{event.id}">--:--:--</div>
              </div>
              <div class="player-container-post" id="player-container-post-#{event.id}"></div>
            </div>
            <div class="bb-grid-item">
              <h1 style="font-size:calc(18px + 0.75vw);margin:25px auto;margin-top:0px!important">
                #{event.title}
              </h1>
              <p style="opacity:0.9;margin-bottom:30px;font-size:calc(1em - 0.15vw);">
                #{event.description}
              </p>
              <p style="margin-bottom:20px">
                <a
                  href="#{link}"
                  class="ltag_cta ltag_cta--branded"
                  role="button"
                  style="font-weight:bold;border-width:2px;width:100%;padding:15px 2px;text-align:center!important;font-size:calc(16px + 0.6vw);display:block"
                >
                  Tune in to the full event
                </a>
              </p>
              <p style="font-size:0.7em;opacity:0.8;margin-bottom:8px;font-style:italic">
                #{Settings::Community.community_name} is partnering to bring live events to the community. Join us or dismiss this billboard if you're not interested. ❤️
              </p>
            </div>
          </div>
          
          <script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.29.1/moment.min.js"></script>
          <script src="https://cdnjs.cloudflare.com/ajax/libs/moment-timezone/0.5.33/moment-timezone-with-data.min.js"></script>
          <script>
            (function() {
              const START_HOUR = #{start_hour};
              const START_MINUTE = #{start_min};
              const IFRAME_SRC = "#{event.primary_stream_url}";

              function getTargetMoment() {
                const nowNY = moment.tz("America/New_York");
                return nowNY.clone().hour(START_HOUR).minute(START_MINUTE).second(0).millisecond(0);
              }

              const overlay = document.getElementById("overlay-post-#{event.id}");
              const countdownEl = document.getElementById("countdown-post-#{event.id}");
              const playerContainer = document.getElementById("player-container-post-#{event.id}");
              let timerId;

              function update() {
                const nowNY = moment.tz("America/New_York");
                const target = getTargetMoment();

                if (nowNY.isSameOrAfter(target)) {
                  clearInterval(timerId);
                  if (overlay) overlay.classList.add("hidden");

                  if (playerContainer && !playerContainer.querySelector("iframe")) {
                    const iframe = document.createElement("iframe");
                    iframe.src = IFRAME_SRC;
                    iframe.allowFullscreen = true;
                    playerContainer.appendChild(iframe);
                  }
                  return;
                }

                if (countdownEl) {
                  const diff = moment.duration(target.diff(nowNY));
                  const hours = String(Math.floor(diff.asHours())).padStart(2, "0");
                  const minutes = String(diff.minutes()).padStart(2, "0");
                  const seconds = String(diff.seconds()).padStart(2, "0");
                  countdownEl.textContent = `${hours}:${minutes}:${seconds}`;
                }
              }

              timerId = setInterval(update, 1000);
              update();
            })();
          </script>
        HTML
      end

      private

      def link
        "/events/#{event.event_name_slug}/#{event.event_variation_slug}"
      end
    end
  end
end

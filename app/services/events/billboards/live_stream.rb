module Events
  module Billboards
    class LiveStream
      attr_reader :event

      def initialize(event)
        @event = event
      end

      def feed_html
        escaped_title = ERB::Util.html_escape(event.title.to_s)
        escaped_description = ERB::Util.html_escape(event.description.to_s)
        escaped_link = ERB::Util.html_escape(link.to_s)
        escaped_community = ERB::Util.html_escape(Settings::Community.community_name)

        <<~HTML
          <style>
            /* 1. The wrapper holds the space and acts as the anchor */
            .media-wrapper-feed {
              position: relative;
              width: 100%;
              height: 51vw;
              background: #000;
              border-radius: 12px;
              margin-bottom: 20px !important;
              overflow: hidden;
            }
            
            @media (min-width: 768px) {
              .media-wrapper-feed {
                height: 340px;
              }
            }

            /* 2. Pin the overlay to the corners of the wrapper */
            .overlay-feed {
              position: absolute;
              top: 0;
              left: 0;
              right: 0;
              bottom: 0;
              color: #fff;
              display: none; /* Hidden by default */
              flex-direction: column;
              align-items: center;
              justify-content: center;
              font-family: sans-serif;
              font-size: calc(1rem + 1vw);
              z-index: 2; /* Keeps overlay on top if needed */
            }
            
            .overlay-feed.active {
              display: flex;
            }
            
            /* 3. Pin the container and iframe to the corners of the wrapper */
            .player-container-feed {
              position: absolute;
              top: 0;
              left: 0;
              right: 0;
              bottom: 0;
              z-index: 1;
            }

            .player-container-feed iframe {
              width: 100%;
              height: 100%;
              border: none;
            }
          </style>
      
          <h1 style="font-size:calc(18px + 0.75vw);margin: 25px auto;margin-top:15px !important">
            #{escaped_title}
          </h1>
      
          <div class="media-wrapper-feed">
            <div class="overlay-feed" id="overlay-feed-#{event.id}">
              <div>Stream starts in…</div>
              <div id="countdown-feed-#{event.id}">--:--:--</div>
            </div>
            <div class="player-container-feed" id="player-container-feed-#{event.id}"></div>
          </div>
      
          <p style="opacity:0.9;margin-bottom:12px;font-size:calc(1em + 0.1vw);">
            #{escaped_description}
          </p>
      
          <p style="margin-bottom:15px">
            <a
              href="#{escaped_link}"
              class="ltag_cta ltag_cta--branded"
              role="button"
              style="font-weight:bold;border-width:2px;width:100%;padding:15px 2px;text-align:center !important;font-size:calc(16px + 0.6vw);display:block"
            >
              Tune in to the full event
            </a>
          </p>
      
          <p style="font-size:0.9em;opacity:0.8;margin-bottom:8px;font-style:italic">
            #{escaped_community} is partnering to bring live events to the community. Join us or dismiss this billboard if you're not interested. ❤️
          </p>
          
          <script>
            (function() {
              const TARGET_TIME = new Date(#{event.start_time.iso8601.to_json}).getTime();
              const IFRAME_SRC = #{event.primary_stream_url.to_json};

              const overlay = document.getElementById("overlay-feed-#{event.id}");
              const countdownEl = document.getElementById("countdown-feed-#{event.id}");
              const playerContainer = document.getElementById("player-container-feed-#{event.id}");
              let timerId;

              function update() {
                const now = Date.now();

                if (now >= TARGET_TIME) {
                  clearInterval(timerId);
                  if (overlay) overlay.classList.remove("active");

                  if (playerContainer && !playerContainer.querySelector("iframe")) {
                    const iframe = document.createElement("iframe");
                    
                    let finalSrc = IFRAME_SRC;
                    try {
                      const url = new URL(finalSrc);
                      if (url.hostname.includes("youtube.com") || url.hostname.includes("youtu.be")) {
                        url.searchParams.set("autoplay", "1");
                        url.searchParams.set("mute", "1");
                      } else if (url.hostname.includes("twitch.tv")) {
                        url.searchParams.set("autoplay", "true");
                        url.searchParams.set("muted", "true");
                      }
                      finalSrc = url.toString();
                    } catch (e) {
                      // ignore
                    }

                    iframe.src = finalSrc;
                    iframe.allow = "autoplay; fullscreen";
                    iframe.allowFullscreen = true;
                    playerContainer.appendChild(iframe);
                  }
                  return;
                }

                if (overlay) overlay.classList.add("active");

                if (countdownEl) {
                  const diffSeconds = Math.max(0, Math.floor((TARGET_TIME - now) / 1000));
                  const hours = String(Math.floor(diffSeconds / 3600)).padStart(2, "0");
                  const minutes = String(Math.floor((diffSeconds % 3600) / 60)).padStart(2, "0");
                  const seconds = String(diffSeconds % 60).padStart(2, "0");
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
        escaped_title = ERB::Util.html_escape(event.title.to_s)
        escaped_description = ERB::Util.html_escape(event.description.to_s)
        escaped_link = ERB::Util.html_escape(link.to_s)
        escaped_community = ERB::Util.html_escape(Settings::Community.community_name)

        <<~HTML
          <style>
            .bb-grid-container {
              display: grid;
              gap: 25px;
              grid-template-columns: 1fr;
              width: 100%;
            }
            
            /* 1. The grid item anchors the elements */
            .bb-grid-item--first {
              display: none;
              background: #000;
              border-radius: 12px;
              min-height: 200px;
              position: relative;
              overflow: hidden;
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
            
            /* 2. Pin overlay to corners */
            .overlay-post {
              position: absolute;
              top: 0;
              left: 0;
              right: 0;
              bottom: 0;
              color: #fff;
              display: none; 
              flex-direction: column;
              align-items: center;
              justify-content: center;
              font-family: sans-serif;
              font-size: calc(1rem + 1vw);
              z-index: 2;
            }
            
            .overlay-post.active {
              display: flex;
            }
            
            /* 3. Pin container and iframe to corners */
            .player-container-post {
              position: absolute;
              top: 0;
              left: 0;
              right: 0;
              bottom: 0;
              z-index: 1;
            }

            .player-container-post iframe {
              width: 100%;
              height: 100%;
              border: none;
            }
            
            @media (min-width: 768px) {
              .bb-grid-container {
                grid-template-columns: 1fr 1fr;
              }
              .bb-grid-item--first {
                display: block; 
                height: 340px;  
              }
            }
            @media (min-width: 1000px) {
              .bb-grid-item:not(.bb-grid-item--first) {
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
                #{escaped_title}
              </h1>
              <p style="opacity:0.9;margin-bottom:30px;font-size:calc(1em - 0.15vw);">
                #{escaped_description}
              </p>
              <p style="margin-bottom:20px">
                <a
                  href="#{escaped_link}"
                  class="ltag_cta ltag_cta--branded"
                  role="button"
                  style="font-weight:bold;border-width:2px;width:100%;padding:15px 2px;text-align:center!important;font-size:calc(16px + 0.6vw);display:block"
                >
                  Tune in to the full event
                </a>
              </p>
              <p style="font-size:0.7em;opacity:0.8;margin-bottom:8px;font-style:italic">
                #{escaped_community} is partnering to bring live events to the community. Join us or dismiss this billboard if you're not interested. ❤️
              </p>
            </div>
          </div>
          
          <script>
            (function() {
              const TARGET_TIME = new Date(#{event.start_time.iso8601.to_json}).getTime();
              const IFRAME_SRC = #{event.primary_stream_url.to_json};

              const overlay = document.getElementById("overlay-post-#{event.id}");
              const countdownEl = document.getElementById("countdown-post-#{event.id}");
              const playerContainer = document.getElementById("player-container-post-#{event.id}");
              let timerId;

              function update() {
                const now = Date.now();

                if (now >= TARGET_TIME) {
                  clearInterval(timerId);
                  if (overlay) overlay.classList.remove("active");

                  if (playerContainer && !playerContainer.querySelector("iframe")) {
                    const iframe = document.createElement("iframe");
                    
                    let finalSrc = IFRAME_SRC;
                    try {
                      const url = new URL(finalSrc);
                      if (url.hostname.includes("youtube.com") || url.hostname.includes("youtu.be")) {
                        url.searchParams.set("autoplay", "1");
                        url.searchParams.set("mute", "1");
                      } else if (url.hostname.includes("twitch.tv")) {
                        url.searchParams.set("autoplay", "true");
                        url.searchParams.set("muted", "true");
                      }
                      finalSrc = url.toString();
                    } catch (e) {
                      // ignore
                    }

                    iframe.src = finalSrc;
                    iframe.allow = "autoplay; fullscreen";
                    iframe.allowFullscreen = true;
                    playerContainer.appendChild(iframe);
                  }
                  return;
                }

                if (overlay) overlay.classList.add("active");

                if (countdownEl) {
                  const diffSeconds = Math.max(0, Math.floor((TARGET_TIME - now) / 1000));
                  const hours = String(Math.floor(diffSeconds / 3600)).padStart(2, "0");
                  const minutes = String(Math.floor((diffSeconds % 3600) / 60)).padStart(2, "0");
                  const seconds = String(diffSeconds % 60).padStart(2, "0");
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

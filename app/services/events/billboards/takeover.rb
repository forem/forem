module Events
  module Billboards
    class Takeover
      attr_reader :event

      def initialize(event)
        @event = event
      end

      def feed_html
        <<~HTML
          <style>
            #event-takeover-image-feed {
              width: 100%;
              height: 51vw;
              object-fit: cover;
            }
            @media (min-width: 768px) {
              #event-takeover-image-feed {
                height: 340px;
              }
            }
          </style>
      
          <h1 style="font-size:calc(18px + 0.75vw);margin: 25px auto;margin-top:15px !important">
            #{event.title}
          </h1>
      
          <img
            id="event-takeover-image-feed"
            src="#{image_url}"
            alt="#{event.title}"
            style="border-radius:12px;margin-bottom:20px !important"
          />
      
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
        HTML
      end

      def post_html
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
            #event-takeover-image {
              width: 100%;
              height: 70%;
              object-fit: cover;
            }
            @media (min-width: 768px) {
              #event-takeover-image {
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
              <img
                id="event-takeover-image"
                src="#{image_url}"
                alt="#{event.title}"
                style="border-radius:12px;margin-bottom:20px!important"
              />
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
        HTML
      end

      private

      def image_url
        event.data["image_url"] || event.organization&.profile_image_url || event.user&.profile_image_url
      end

      def link
        "/events/#{event.event_name_slug}/#{event.event_variation_slug}"
      end
    end
  end
end

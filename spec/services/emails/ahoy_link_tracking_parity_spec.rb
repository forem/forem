require "rails_helper"

# The two callers of Emails::AhoyLinkTracking rewrite different things: the
# AhoyEmail::Processor patch rewrites the rendered body for SMTP, and
# Emails::AhoyLinkDecorator rewrites the Customer.io message_data payload.
# Sharing the module makes them agree on how a URL is built, but not on which
# URLs they choose to build -- the skip rules, the internal/external split and
# the url_options each caller supplies all live outside it.
#
# A divergence there is silent: Ahoy::EmailClicksController#verify_signature
# just rejects the click. So drive both paths over the same markup with the same
# token and require the results to be identical.
RSpec.describe "Ahoy link tracking parity", type: :mailer do
  let(:domain) { Settings::General.app_domain }
  let(:markup) do
    <<~HTML
      <a href="https://#{domain}/ben/some-post?context=digest">Internal</a>
      <a href="https://example.com/outside">External</a>
      <a href="https://#{domain}/email_subscriptions/unsubscribe?ut=abc">Unsubscribe</a>
      <a href="https://#{domain}/ahoy/click?t=old&s=oldsig&u=https%3A%2F%2Fexample.com">Already tracked</a>
      <a href="https://#{domain}/sponsor?bb=42">Billboard</a>
    HTML
  end

  def hrefs(html)
    Nokogiri::HTML::DocumentFragment.parse(html).css("a[href]").pluck("href")
  end

  before do
    stub_const("ParityMailer", Class.new(ApplicationMailer) do
      def sample(body, subject)
        mail(to: "member@example.com", subject: subject, body: body, content_type: "text/html")
      end
    end)
  end

  it "rewrites the body and the payload to exactly the same hrefs" do
    message = ParityMailer.sample(markup, "Parity").message
    ahoy_data = message.ahoy_data

    smtp_hrefs = hrefs(message.body.decoded)
    payload = Emails::AhoyLinkDecorator.call({ "html" => markup }, ahoy_data: ahoy_data)
    customerio_hrefs = hrefs(payload["html"])

    # Guard against a vacuous pass: if neither path decorated anything, the
    # comparison below would succeed while proving nothing.
    expect(smtp_hrefs.grep(/ahoy_click=true/)).not_to be_empty
    expect(smtp_hrefs).to eq(customerio_hrefs)
  end

  it "agrees on a bare URL too, not just anchors in HTML" do
    url = "https://#{domain}/ben/some-post?context=digest"
    message = ParityMailer.sample(%(<a href="#{url}">Read</a>), "Parity").message

    smtp_href = hrefs(message.body.decoded).first
    decorated = Emails::AhoyLinkDecorator.call({ "url" => url }, ahoy_data: message.ahoy_data)

    expect(decorated["url"]).to eq(smtp_href)
  end
end

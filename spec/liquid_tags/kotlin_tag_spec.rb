require "rails_helper"

RSpec.describe KotlinTag, type: :liquid_template do
  describe "#link" do

    def generate_new_liquid(link)
      Liquid::Template.register_tag("kotlin", KotlinTag)
      Liquid::Template.parse("{% kotlin #{link} %}")
    end

    it "accepts only Kotlin Playground links" do
      badurl = 'https://example.com'
      expect do
        generate_new_liquid(badurl)
      end.to raise_error(StandardError)

      badurl = 'not even an URL'
      expect do
        generate_new_liquid(badurl)
      end.to raise_error(StandardError)
    end

    def check(url, expected)
      expect(KotlinTag.parse_link(url)).to eq(expected)
    end

    it "parses URL correctly" do
      check("https://pl.kotl.in/owreUFFUG", {:from =>"", :readOnly =>"", :short =>"owreUFFUG", :theme =>"", :to => ""})
      check("https://pl.kotl.in/owreUFFUG?theme=dracula&from=3&to=6&readOnly=true",  {:from =>"3", :readOnly =>"true", :short =>"owreUFFUG", :theme =>"dracula", :to =>"6"})
      check("https://pl.kotl.in/owreUFFUG?theme=dracula&readOnly=true", {:from =>"", :readOnly =>"true", :short =>"owreUFFUG", :theme =>"dracula", :to =>""})
      check("https://pl.kotl.in/owreUFFUG?from=3&to=6", {:from =>"3", :readOnly =>"", :short =>"owreUFFUG", :theme =>"", :to =>"6"})
    end

    it "renders correctly a Kotlin Playground link" do
      liquid = generate_new_liquid("https://pl.kotl.in/owreUFFUG?theme=dracula&from=3&to=6&readOnly=true")
      rendered_kotlin_iframe = liquid.render
      Approvals.verify(rendered_kotlin_iframe, name: "kotlin_liquid_tag", format: :html)
    end
  end
end

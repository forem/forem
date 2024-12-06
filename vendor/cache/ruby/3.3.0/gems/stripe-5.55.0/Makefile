.PHONY: update-version codegen-format
update-version:
	@echo "$(VERSION)" > VERSION
	@perl -pi -e 's|VERSION = "[.\d]+"|VERSION = "$(VERSION)"|' lib/stripe/version.rb

codegen-format:
	bundle exec rubocop -o /dev/null --auto-correct

# Trigger cache purges for globally-cached endpoints that could have changed
CacheBuster.bust("/shell_top")
CacheBuster.bust("/shell_bottom")
CacheBuster.bust("/async_info/shell_version")
CacheBuster.bust("/onboarding")

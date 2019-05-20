.PHONY: build

build: ruby-doc gitdocs

ruby-doc:
  # docs/.static/ruby-doc will let gitdocs serve the Ruby doc as static content
	cd .. && yard doc -o docs/.static/ruby-doc

gitdocs:
	npm install -g gitdocs@latest && gitdocs build

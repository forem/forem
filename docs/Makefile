.PHONY: build

build: api-doc ruby-doc gitdocs

api-doc:
  # docs/.static/api will let gitdocs serve the API doc as static content
	yarn redoc-cli bundle docs/api_v0.yml --options.suppressWarnings --options.pathInMiddlePanel --options.jsonSampleExpandLevel=all --options.menuToggle -t docs/api_template.hbs &&\
	mkdir -p .static/api/ &&\
  mv ../redoc-static.html .static/api/index.html

ruby-doc:
  # docs/.static/ruby-doc will let gitdocs serve the Ruby doc as static content
	cd .. && yard doc -o docs/.static/ruby-doc

gitdocs:
	npm install -g gitdocs@latest && gitdocs build

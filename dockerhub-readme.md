# How do I get this up and running quickly

Note: You will need replace all the various `<values>`

```bash
# Run a postgres server configured for dev.to
docker run -d --name dev-to-postgres \
    -e POSTGRES_PASSWORD=devto \
    -e POSTGRES_USER=devto \
    -e POSTGRES_DB=PracticalDeveloper_development \
    -v "<POSTGRES_DATA>:/var/lib/postgresql/data" \
    postgres:10.7-alpine;

# Wait about 30 seconds, to give the postgres container time to start
sleep 30

#
# Run the prebuilt dev.to container
# binded to localhost:3000
#
# Algoliasearch key is a hard requirements,
# for login do consider adding github/twitter keys
# see : https://github.com/thepracticaldev/dev.to/blob/master/config/sample_application.yml
#
docker run -d -p 3000:3000 \
    --name dev-to-app \
    --link dev-to-postgres:db \
    -v "<DEVTO_UPLOAD_DIR>:/usr/src/app/public/uploads/" \
    -e ALGOLIASEARCH_APPLICATION_ID=<APP_ID> \
    -e ALGOLIASEARCH_SEARCH_ONLY_KEY=<SEARH_KEY> \
    -e ALGOLIASEARCH_API_KEY=<ADMIN_KEY> \
    uilicious/dev.to
```

> PS : Someone from official dev.to team should create their own container namespace and update this segment after merger (if any)

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

> PS : Someone from official dev.to team should create their own container namespace and update this segment after merger (if any)
```

## To say honestly I'm not happy with the current code quality of this project.

But I don't have time to refactor it.

## Development environment 

Clone project and perform following actions
```
docker-compose up
```

Attach to cotnainer:

```
docker exec -it [container-name] /bin/bash
```

and then, inside container

```
jekyll serve --host 0.0.0.0
```
Then the application is available on localhost:4000

To stop container:
```
docker-compose stop
```
## Development environment 

Clone project in [clone-dir]
```
cd ..
docker built -t private/myblog [clone-dir]
docker run -i -t -d --name "myblog" -v [clone-dir]:/root/src -p 4000:4000 private/myblog /bin/bash
docker exec -it myblog /bin/bash
```

and then, inside container

```
cd ~/src
jekyll serve --host 0.0.0.0
```
Then the application is available on localhost:4000

To stop container:
```
docker stop [container_name]
```
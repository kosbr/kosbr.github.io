---
layout: post
title:  "Creating docker swarm cluster"
date:   2017-09-19 10:30:39 +0600
categories:
tags: Docker
---

### Step 1: Create network

{% highlight bash %}
docker network create \
  --driver overlay \
  my-network
{% endhighlight %}


### Step 2: Add visualization to your cluster

{% highlight bash %}
docker service create \
--name portainer \
--publish 9000:9000 \
--constraint 'node.role == manager' \
--mount type=bind,src=//var/run/docker.sock,dst=/var/run/docker.sock \
  portainer/portainer \
-H unix:///var/run/docker.sock
{% endhighlight %}


### Step 3: Add nodes


{% highlight bash %}
docker swarm join-token worker
{% endhighlight %}

or

{% highlight bash %}
docker swarm join-token manager
{% endhighlight %}


### Step 4: Set labels to nodes

{% highlight bash %}
docker node update --label-add cassandra2=true cassandra2
docker node update --label-add cassandra1=true cassandra1
docker node update --label-add elastic=true elastic
docker node update --label-add cassandra3=true cassandra3
docker node update --label-add worker=true worker1
docker node update --label-add worker=true worker2
docker node update --label-add worker=true worker3
docker node update --label-add worker=true worker4
docker node update --label-add worker=true worker5
docker node update --label-add worker=true worker6
{% endhighlight %}

### Step 5: Creating a cassandra cluster

On every cassandra node

{% highlight bash %}
mkdir /cassandra-data
{% endhighlight %}

And then from the manager node:

{% highlight bash %}
docker service create \
  --name cassandra1 \
  --replicas=1 \
  --network my-network \
  --publish 9042:9042 \
  --env CASSANDRA_BROADCAST_ADDRESS=cassandra1 \
  --env CASSANDRA_SEEDS=cassandra2,cassandra3 \
  --mount type=bind,source=/cassandra-data,destination=/var/lib/cassandra \
  --constraint 'node.labels.cassandra1 == true' \
  --limit-memory="2500m" \
  --reserve-memory="2500m" \
  repo.treescale.com/kosbr/cassandra:3.11

docker service create \
  --name cassandra2 \
  --replicas=1 \
  --network my-network \
  --publish 9043:9042 \
  --env CASSANDRA_BROADCAST_ADDRESS=cassandra2 \
  --env CASSANDRA_SEEDS=cassandra1,cassandra3 \
  --mount type=bind,source=/cassandra-data,destination=/var/lib/cassandra \
  --constraint 'node.labels.cassandra2 == true' \
  --limit-memory="2500m" \
  --reserve-memory="2500m" \
  repo.treescale.com/kosbr/cassandra:3.11
  
  docker service create \
  --name cassandra3 \
  --replicas=1 \
  --network my-network \
  --publish 9044:9042 \
  --env CASSANDRA_BROADCAST_ADDRESS=cassandra3 \
  --env CASSANDRA_SEEDS=cassandra1,cassandra2 \
  --mount type=bind,source=/cassandra-data,destination=/var/lib/cassandra \
  --constraint 'node.labels.cassandra3 == true' \
  --limit-memory="2500m" \
  --reserve-memory="2500m" \
  repo.treescale.com/kosbr/cassandra:3.11
{% endhighlight %}

Then, create keyspace with simple replication strategy and replications number = 2. Don't
forget to use proper strategy for writing and reading data from the cluster. (wait only
one response while reading or writing data to the cluster)

### Step 6: Create redis

{% highlight bash %}
docker config create redisconf redis.conf
docker service  create  \
    --name redis \
    --publish 6379:6379 \
    --network my-network \
    --config redisconf \
    --constraint 'node.labels.worker == true' \
     --limit-memory="1500m" \
     --reserve-memory="1500m" \
     redis:3.2.0 redis-server /redisconf

{% endhighlight %}

If redis is moved, data will be destroyed. Sometimes it is ok.

### Step7: Create elasticseach service

On elastic node
{% highlight bash %}
sysctl -w vm.max_map_count=262144
mkdir /es-data
chmod -R 777 /es-data/
{% endhighlight %}


{% highlight bash %}
docker service create --name elastic \
  --network my-network \
  --constraint 'node.labels.elastic == true' \
  -p 9200:9200 \
  -p 9301:9301 \
  --mount type=bind,source=/es-data,destination=/usr/share/elasticsearch/data \
  --limit-memory="2800m" \
  --reserve-memory="2800m" \
  docker.elastic.co/elasticsearch/elasticsearch:5.5.2

{% endhighlight %}

issues with network.publish_host???

### Step 8: Add Kibana to cluster

{% highlight bash %}
docker service create --name kibana \
  --network my-network \
  --constraint 'node.labels.worker == true' \
  --env ELASTICSEARCH_URL=http://elastic:9200 \
  --env ELASTICSEARCH_USERNAME=elastic \
  --env ELASTICSEARCH_PASSWORD=changeme \
  --env SERVER_PORT=5601 \
  --limit-memory="2000m" \
  --reserve-memory="2000m" \
  -p 5601:5601 \
docker.elastic.co/kibana/kibana:5.5.2
{% endhighlight %}

### Step 9: Add storage application

{% highlight bash %}
docker service create --name storage \
  --network my-network \
  --replicas=1 \
  --constraint 'node.labels.worker == true' \
  --env LOG_DIR=/var/log/guestbook-storage \
  --limit-memory="1800m" \
  --reserve-memory="1800m" \
  -p 8081:8081 \
repo.treescale.com/kosbr/guestbook/storage:1.6
{% endhighlight %}


{% highlight bash %}
docker service create --name gate \
  --network my-network \
  --replicas=1 \
  --constraint 'node.labels.worker == true' \
  --env LOG_DIR=/var/log/guestbook-gate \
  --limit-memory="1800m" \
  --reserve-memory="1800m" \
  -p 8082:8082 \
repo.treescale.com/kosbr/guestbook/gate:1.0-SNAPSHOT
{% endhighlight %}












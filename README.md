# Ruby Kafka Bug

Demonstration of the bug that happens with different consumers in the same group subscribed to different topics.

## How to replicate it

Clone the repository:
```
git clone git@github.com:lairtonlelis/ruby-kafka-bug.git
```

Setup a local kafka instance if you don't have one already:

create a `docker-compose.yml`:
```yaml
version: '3.1'

services:
  zoo1:
    image: zookeeper:3.4.9
    hostname: zoo1
    ports:
      - "2181:2181"
    environment:
        ZOO_MY_ID: 1
        ZOO_PORT: 2181
        ZOO_SERVERS: server.1=zoo1:2888:3888
    volumes:
      - ./zk-single-kafka-single/zoo1/data:/data
      - ./zk-single-kafka-single/zoo1/datalog:/datalog

  kafka1:
    image: confluentinc/cp-kafka:5.2.2
    hostname: kafka1
    ports:
      - "9092:9092"
    environment:
      KAFKA_ADVERTISED_LISTENERS: LISTENER_DOCKER_INTERNAL://kafka1:19092,LISTENER_DOCKER_EXTERNAL://${DOCKER_HOST_IP:-127.0.0.1}:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: LISTENER_DOCKER_INTERNAL:PLAINTEXT,LISTENER_DOCKER_EXTERNAL:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: LISTENER_DOCKER_INTERNAL
      KAFKA_ZOOKEEPER_CONNECT: "zoo1:2181"
      KAFKA_BROKER_ID: 1
      KAFKA_LOG4J_LOGGERS: "kafka.controller=INFO,kafka.producer.async.DefaultEventHandler=INFO,state.change.logger=INFO"
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    volumes:
      - ./zk-single-kafka-single/kafka1/data:/var/lib/kafka/data
    depends_on:
      - zoo1
```

Start kafka with:
```
docker-compose up
```

### Start consumers

Start two consumers simultaneously, preferrably on different consoles, with the commands:

```
ruby app.rb my-client group my-topic
```

```
ruby app.rb my-client-2 group my-topic-2
```

### The bug
Stop them using `CTRL+C`, and try to start them simultaneously again.
You should see the following exception on the second consumer:
```
Traceback (most recent call last):
  17: from app.rb:28:in `<main>'
  16: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/consumer.rb:211:in `each_message'
  15: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/consumer.rb:403:in `consumer_loop'
  14: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/instrumenter.rb:35:in `instrument'
  13: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/instrumenter.rb:23:in `instrument'
  12: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/consumer.rb:404:in `block in consumer_loop'
  11: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/consumer.rb:212:in `block in each_message'
  10: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/consumer.rb:519:in `fetch_batches'
   9: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/consumer.rb:475:in `join_group'
   8: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/consumer.rb:475:in `each'
   7: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/consumer.rb:476:in `block in join_group'
   6: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/consumer.rb:476:in `each'
   5: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/consumer.rb:480:in `block (2 levels) in join_group'
   4: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/consumer.rb:492:in `seek_to_next'
   3: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/offset_manager.rb:103:in `next_offset_for'
   2: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/offset_manager.rb:183:in `resolve_offset'
   1: from /home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/offset_manager.rb:188:in `fetch_resolved_offsets'
/home/lairton-debian/.rvm/gems/ruby-2.6.3/gems/ruby-kafka-0.7.9/lib/kafka/offset_manager.rb:188:in `fetch': key not found: "my-topic" (KeyError)
```

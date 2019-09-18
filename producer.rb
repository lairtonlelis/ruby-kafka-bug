# frozen_string_literal: true

require 'bundler/setup'

Bundler.require

require 'kafka'

topic = ARGV[0]
messages = ARGV[1].to_i || 0

kafka = Kafka.new(
  ENV.fetch('KAFKA_BROKERS', 'localhost:9092').split(',')
)

messages.times { kafka.deliver_message('Hello, World!', topic: topic) }
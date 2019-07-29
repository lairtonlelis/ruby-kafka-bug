# frozen_string_literal: true

lib_dir = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require 'bundler/setup'

Bundler.require

require 'kafka'

client_id = ARGV[0]
group_id = ARGV[1]
topic = ARGV[2]

kafka = Kafka.new(
  ENV.fetch('KAFKA_BROKERS', 'localhost:9092').split(','),
  client_id: client_id
)

consumer = kafka.consumer(group_id: group_id)

consumer.subscribe(topic)

trap('TERM') { consumer.stop }
trap('INT') { consumer.stop }

consumer.each_message do |message|
  puts message.offset, message.key, message.value
end

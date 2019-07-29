require 'kafka'

module RubyKafkaBug
  def self.call(client_id:, group_id:, topic:)
    kafka = Kafka.new(ENV.fetch('KAFKA_BROKERS', 'localhost:9092').split(','), client_id: client_id)

    consumer = kafka.consumer(group_id: group_id)

    consumer.subscribe(topic)

    trap('TERM') { consumer.stop }
    trap('INT') { consumer.stop }

    consumer.each_message do |message|
      puts message.offset, message.key, message.value
    end
  end
end

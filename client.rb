require 'websocket-client-simple'
require 'json'

class WebSocketClient
  attr_accessor :url, :received_messages, :stop, :channel_identifier, :ws_thread, :ws, :connected, :client_id
  def initialize(url, channel = "VlhmConnect")
    @url = url
    @received_messages = Queue.new
    @stop = false
    @channel_identifier = {channel: channel}.to_json
    @connected = false
    @client_id = "#{Time.now.to_i}-#{rand(1000)}"
  end

  def connect
    @ws_thread = Thread.new do

      begin
        @ws = WebSocket::Client::Simple.connect(@url)
      rescue => e
        puts "!!!Failed to connect!!!: #{e.message}"
        @connected = false
        return
      end

      current_self = self

      @ws.on :open do
        puts "!!!WebSocket connected!!!"
        current_self.connected = true

        data = {
          command: "subscribe",
          identifier: current_self.channel_identifier
        }.to_json
        current_self.ws.send(data)
      end

      @ws.on :message do |msg|
        data = JSON.parse(msg.data)

        unless current_self.is_system_message?(data)
          # if data['message']['sender_id'] != current_self.client_id
          #   current_self.received_messages << data['message']
          # end
          current_self.received_messages << data['message']
        end
      end

      @ws.on :close do |e|
        p "!!!Connection closed!!!"
        @connected = false
      end

      @ws.on :error do |e|
        puts "!!!Error!!!: #{e.message}"
      end

      # Keep the WebSocket connection alive
      loop do
        # p '!!!@stop!!!' if @stop
        break if @stop
        sleep 0.1
      end
    end
  end

  def send_signal_message(message)
    begin
      data = {
        command: "message",
        identifier: @channel_identifier,
        data: {action: 'signal_message', message: message, client_id: @client_id}.to_json
      }.to_json
      @ws.send(data) if @connected
    rescue => e
      puts "Failed to send message (in method 'send_message'): #{e.message}"
    end
  end

  def send_text_message(message)
    begin
      data = {
        command: "message",
        identifier: @channel_identifier,
        data: {action: 'text_message', message: message, client_id: @client_id}.to_json
      }.to_json
      @ws.send(data) if @connected
    rescue => e
      puts "Failed to send message (in method 'send_message'): #{e.message}"
    end
  end

  def read_message
    begin
      return @received_messages.pop(true)
    rescue ThreadError
      return nil
    end
  end

  def is_connected?
    @connected
  end

  def stop
    @stop = true
    @ws.close if @ws
    @ws_thread.join if @ws_thread
  end

  def is_system_message?(data)
    if (data['type'] == "welcome") || (data['type'] == "confirm_subscription") || (data['type'] == "ping")
      true
    elsif data['message']['message'] == 'ping'
      true
    else
      false
    end
  end
end

require 'fox16'

require 'net/http'
require 'uri'

include Fox
require_relative 'client.rb'
require_relative 'canvas_item.rb'
require_relative 'win_api.rb'


# URL = "ws://localhost:3000/cable"
URL = "wss://v-connect-q36m.onrender.com/cable"
HTTP_URL = "https://v-connect-q36m.onrender.com"


class MyApp < FXMainWindow
  def initialize(app)
    super(app, "Valheim Connect", width: 120, height: 370)


    @client = WebSocketClient.new(URL)
    @signal_buttons = []
    @signal_buttons_content = {
      '1' => 'OK',
      '2' => 'HELP',
      '3' => 'GO-GO',
      '4' => 'FuckYou'
    }
    @sender_ids = {}
    @sender_id_counter = 0
    @last_signal_timestamp = 0

    # TIMEOUTS
    @ping_server_timeout = 60000
    @check_cycle_timeout = 100


    # FONT
    @font = FXFont.new(app, "Console", 8, FXFont::Bold)


    # COLORS
    @color_background = Fox.FXRGB(1, 46, 63)
    @color_green_1 = Fox.FXRGB(1, 80, 89)
    @color_green_2 = Fox.FXRGB(2, 140, 140)
    @color_green_3 = Fox.FXRGB(3, 165, 149)
    @color_orange = Fox.FXRGB(242, 135, 4)
    @color_dark = Fox.FXRGB(10, 66, 83)
    @color_text = Fox.FXRGB(255, 255, 255)

    self.backColor = @color_background


    # BUTTON_CONNECT
    @button_connect = FXButton.new(self, "Connect", nil, nil, 0,
    BUTTON_NORMAL | LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT | LAYOUT_FIX_X | LAYOUT_FIX_Y,
    10, 10, 100, 30)

    @button_connect.backColor = @color_green_1
    @button_connect.textColor = @color_text
    @button_connect.font = @font

    @button_connect.connect(SEL_COMMAND) do
      return if @client.is_connected?
      @client.connect
      check_cycle
      ping_server
    end


    # SIGNAL_ITEMS
    @signal_item_1 = SignalItem.new(self, 90, 50, 20, 30, Fox.FXRGB(18, 255,  42))
    @signal_item_2 = SignalItem.new(self, 90, 90, 20, 30, Fox.FXRGB(8, 230, 255))
    @signal_item_3 = SignalItem.new(self, 90, 130, 20, 30, Fox.FXRGB(255, 251, 41))
    @signal_item_4 = SignalItem.new(self, 90, 170, 20, 30, Fox.FXRGB(121, 18, 255))


    # SIGNAL_BUTTONS
    @signal_buttons << FXButton.new(self, @signal_buttons_content['1'], nil, nil, 0,
    BUTTON_NORMAL | LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT | LAYOUT_FIX_X | LAYOUT_FIX_Y,
    10, 50, 70, 30)

    @signal_buttons << FXButton.new(self, @signal_buttons_content['2'], nil, nil, 0,
    BUTTON_NORMAL | LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT | LAYOUT_FIX_X | LAYOUT_FIX_Y,
    10, 90, 70, 30)

    @signal_buttons << FXButton.new(self, @signal_buttons_content['3'], nil, nil, 0,
    BUTTON_NORMAL | LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT | LAYOUT_FIX_X | LAYOUT_FIX_Y,
    10, 130, 70, 30)

    @signal_buttons << FXButton.new(self, @signal_buttons_content['4'], nil, nil, 0,
    BUTTON_NORMAL | LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT | LAYOUT_FIX_X | LAYOUT_FIX_Y,
    10, 170, 70, 30)

    @signal_buttons.each_with_index do |button, index|
      button.backColor = @color_green_1
      button.textColor = @color_text
      button.font = @font

      button.connect(SEL_COMMAND) do
        button.backColor = @color_green_2
        @client.send_signal_message("#{index + 1}")
        FXApp.instance.addTimeout(150) do
          button.backColor = @color_green_1
        end
      end
    end


    # CHAT
    @input_field = FXTextField.new(self, 20, nil, 0, TEXTFIELD_NORMAL | LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT | LAYOUT_FIX_X | LAYOUT_FIX_Y, 10, 210, 100, 30)

    @input_field.font = @font

    button_send = FXButton.new(self, "Send", nil, nil, 0,
    BUTTON_NORMAL | LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT | LAYOUT_FIX_X | LAYOUT_FIX_Y,
    10, 250, 70, 30)

    button_send.connect(SEL_COMMAND) do
      message = @input_field.text
      @client.send_text_message(message) unless message.empty?
      @input_field.setText('')
    end

    @text_display = FXText.new(self, nil, 0, TEXT_WORDWRAP | TEXT_READONLY | LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT | LAYOUT_FIX_X | LAYOUT_FIX_Y, 10, 290, 100, 70)
    @text_display.font = @font
    @text_display.backColor = @color_dark
    @text_display.textColor = @color_text
  end

  def signal_button_color_change(button)
    button.backColor = @color_green_2
    FXApp.instance.addTimeout(150) do
      button.backColor = @color_green_1
    end
  end

  def check_cycle
    if WinAPI.check_key(97) || WinAPI.check_key(36)
      if (Time.now.to_f * 1000).to_i - @last_signal_timestamp > 250
        @client.send_signal_message("1")
        signal_button_color_change(@signal_buttons[0])
        @last_signal_timestamp = (Time.now.to_f * 1000).to_i
      end
    end
    if WinAPI.check_key(98) || WinAPI.check_key(35)
      if (Time.now.to_f * 1000).to_i - @last_signal_timestamp > 250
        @client.send_signal_message("2")
        signal_button_color_change(@signal_buttons[1])
        @last_signal_timestamp = (Time.now.to_f * 1000).to_i
      end
    end
    if WinAPI.check_key(99) || WinAPI.check_key(33)
      if (Time.now.to_f * 1000).to_i - @last_signal_timestamp > 250
        @client.send_signal_message("3")
        signal_button_color_change(@signal_buttons[2])
        @last_signal_timestamp = (Time.now.to_f * 1000).to_i
      end
    end
    if WinAPI.check_key(96) || WinAPI.check_key(34)
      if (Time.now.to_f * 1000).to_i - @last_signal_timestamp > 250
        @client.send_signal_message("4")
        signal_button_color_change(@signal_buttons[3])
        @last_signal_timestamp = (Time.now.to_f * 1000).to_i
      end
    end

    # CHANGE CLOLOR OF @button_connect
    if @client.is_connected?
      if @button_connect.backColor != @color_green_3
        @button_connect.backColor = @color_green_3
      end
    end
    if !@client.is_connected?
      @button_connect.backColor = @color_orange
    end

    get_messages

    @check_cycle_timer = FXApp.instance.addTimeout(@check_cycle_timeout) { check_cycle }
  end

  def get_messages
    while (message = @client.read_message)
      if message['type'] == 'signal_message'
        append_message(message['sender_id'], @signal_buttons_content[message['message']])
        return if message['sender_id'] == @client.client_id
        case message['message']
          when "1"
            @signal_item_1.change_color
          when "2"
            @signal_item_2.change_color
          when "3"
            @signal_item_3.change_color
          when "4"
            @signal_item_4.change_color
        end
        next
      end

      if message['type'] == 'text_message'
        append_message(message['sender_id'], message['message'])
      end
    end
  end

  def append_message(sender_id, message)
    if sender_id == @client.client_id
      @text_display.appendText("me: #{message}\n")
      @text_display.makePositionVisible(@text_display.length)
    else
      if @sender_ids[sender_id].nil?
        @sender_id_counter += 1
        @sender_ids[sender_id] = "u-#{@sender_id_counter}"
      end
      @text_display.appendText("#{@sender_ids[sender_id]}: #{message}\n")
      @text_display.makePositionVisible(@text_display.length)
    end
  end

  def ping_server
    @ping_timer = FXApp.instance.addTimeout(@ping_server_timeout) do
      ping_websocket
      ping_http
      ping_server
    end
  end

  def ping_websocket
    @client.send_text_message('ping')
  end

  def ping_http
    Thread.new do
      uri = URI.parse(HTTP_URL)
      response = Net::HTTP.get_response(uri)
      time = Time.now
      hours = time.strftime("%H")
      minutes = time.strftime("%M")
      p "code: #{response.code}, time: #{hours}:#{minutes}"
    end
  end

  def create
    super
    show(PLACEMENT_SCREEN)
    WinAPI.make_window_always_on_top(self.title.encode('UTF-16LE'))
    WinAPI.remove_window_buttons(self.title.encode('UTF-16LE'))
  end
end



if __FILE__ == $0
  app = FXApp.new
  MyApp.new(app)
  app.create
  app.run
end

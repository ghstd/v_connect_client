require 'fox16'
include Fox
require_relative 'client.rb'
require_relative 'canvas_item.rb'
require_relative 'win_api.rb'


# URL = "ws://localhost:3000/cable"
URL = "wss://v-connect-q36m.onrender.com/cable"


class MyApp < FXMainWindow
  def initialize(app)
    super(app, "Valheim Connect", width: 120, height: 350)


    @client = WebSocketClient.new(URL)
    @signal_buttons = []


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
    button_connect = FXButton.new(self, "Connect", nil, nil, 0,
    BUTTON_NORMAL | LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT | LAYOUT_FIX_X | LAYOUT_FIX_Y,
    10, 10, 100, 30)

    button_connect.backColor = @color_green_1
    button_connect.textColor = @color_text
    button_connect.font = @font

    button_connect.connect(SEL_COMMAND) do
      @client.connect
      check_messages
      FXApp.instance.addTimeout(5000) do
        if @client.is_connected?
          button_connect.backColor = @color_green_3
        else
          button_connect.backColor = @color_orange
        end
      end
    end


    # SIGNAL_ITEMS
    @signal_item_1 = SignalItem.new(self, 90, 50, 20, 30, Fox.FXRGB(18, 255,  42))
    @signal_item_2 = SignalItem.new(self, 90, 90, 20, 30, Fox.FXRGB(8, 230, 255))
    @signal_item_3 = SignalItem.new(self, 90, 130, 20, 30, Fox.FXRGB(255, 251, 41))
    @signal_item_4 = SignalItem.new(self, 90, 170, 20, 30, Fox.FXRGB(121, 18, 255))


    # SIGNAL_BUTTONS
    @signal_buttons << FXButton.new(self, "ПРИНЯЛ", nil, nil, 0,
    BUTTON_NORMAL | LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT | LAYOUT_FIX_X | LAYOUT_FIX_Y,
    10, 50, 70, 30)

    @signal_buttons << FXButton.new(self, "ПОДОЙДИ", nil, nil, 0,
    BUTTON_NORMAL | LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT | LAYOUT_FIX_X | LAYOUT_FIX_Y,
    10, 90, 70, 30)

    @signal_buttons << FXButton.new(self, "ЧИТАЙ", nil, nil, 0,
    BUTTON_NORMAL | LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT | LAYOUT_FIX_X | LAYOUT_FIX_Y,
    10, 130, 70, 30)

    @signal_buttons << FXButton.new(self, "FuckYou", nil, nil, 0,
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

    @text_display = FXText.new(self, nil, 0, TEXT_WORDWRAP | TEXT_READONLY | LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT | LAYOUT_FIX_X | LAYOUT_FIX_Y, 10, 290, 100, 50)
    @text_display.font = @font
    @text_display.backColor = @color_dark
    @text_display.textColor = @color_text
  end

  def check_messages
    @check_messages_timer = FXApp.instance.addTimeout(100) do
      get_messages
      @check_messages_timer = FXApp.instance.addTimeout(100) { check_messages }
    end
  end

  def get_messages
    while (message = @client.read_message)
      if message['type'] == 'signal_message'
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
        @text_display.setText(message['message'])
      end
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

class SignalItem < FXCanvas
  def initialize(p, x, y, width, height, signal_color = Fox.FXRGB(0, 0, 0), base_color = Fox.FXRGB(211, 211, 211))
    super(p, nil, 0, LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT | LAYOUT_FIX_X | LAYOUT_FIX_Y, x, y, width, height)

    @base_color = base_color
    @signal_color = signal_color
    @current_color = @base_color
    @change_color_timeout = 150

    self.connect(SEL_PAINT) do
      draw(x, y, width, height)
    end
  end

  def draw(x, y, width, height)
    dc = FXDCWindow.new(self)
    dc.foreground = @current_color
    dc.fillRectangle(0, 0, width, height)
    dc.end
  end

  def change_color(custom_color = @signal_color)
    @current_color = custom_color
    FXApp.instance.addTimeout(@change_color_timeout) do
      @current_color = @base_color
      update
    end
    self.update
  end

end

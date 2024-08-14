require 'ffi'

module WinAPI
  extend FFI::Library
  ffi_lib 'user32'

  # Определяем функции из user32.dll
  attach_function :SetWindowPos, [:uintptr_t, :uintptr_t, :int, :int, :int, :int, :uint], :int
  attach_function :GetWindowLongW, [:pointer, :int], :long_long
  attach_function :SetWindowLongW, [:pointer, :int, :long_long], :long_long
  attach_function :GetWindowRect, [:pointer, :pointer], :bool
  attach_function :InvalidateRect, [:pointer, :pointer, :bool], :bool
  attach_function :FindWindowW, [:string, :string], :uintptr_t

  # Определяем константы
  SWP_NOSIZE = 0x0001
  SWP_NOMOVE = 0x0002
  HWND_TOPMOST = -1
  GWL_STYLE = -16
  WS_SYSMENU = 0x00080000
  WS_MAXIMIZEBOX = 0x00010000
  WS_MINIMIZEBOX = 0x00020000

  def self.make_window_always_on_top(title)
    hwnd = WinAPI::FindWindowW(nil, title)
    WinAPI::SetWindowPos(hwnd, WinAPI::HWND_TOPMOST, 0, 0, 0, 0, WinAPI::SWP_NOSIZE | WinAPI::SWP_NOMOVE)
  end

  def self.remove_window_buttons(title)
    # Найти дескриптор окна по заголовку
    hwnd = WinAPI.FindWindowW(nil, title)
    hwnd_pointer = FFI::Pointer.new(hwnd)

    # Проверка на корректность дескриптора окна
    if hwnd_pointer.null?
      raise ArgumentError, "Invalid window handle"
    end

    # Получаем текущие стили окна
    style = WinAPI.GetWindowLongW(hwnd_pointer, WinAPI::GWL_STYLE)

    # Убираем кнопки "свернуть", "развернуть" и "закрыть"
    # WinAPI::WS_SYSMENU
    new_style = style & ~(WinAPI::WS_MAXIMIZEBOX | WinAPI::WS_MINIMIZEBOX)

    # Устанавливаем новые стили
    WinAPI.SetWindowLongW(hwnd_pointer, WinAPI::GWL_STYLE, new_style)

    # Обновляем окно
    WinAPI.InvalidateRect(hwnd_pointer, nil, true)
  end
end

require 'libhid-ruby'

module WMR
  def self.send_init_packet(interface)
    path_in = FFI::Buffer.new :int, 2
    LibHID::Native.write_bignum32_array path_in, PATH_IN

    init_packet = FFI::MemoryPointer.new(INIT_PACKET1.size * 1).write_array_of_char(INIT_PACKET1)
    result = LibHID::Native.hid_set_output_report(interface.to_ptr, path_in, 2, init_packet, init_packet.size)
    # LibHID.check_result "Sending init packet", result
  end

  def self.send_ready_packet(interface)
    path_in = FFI::Buffer.new :int, 2
    LibHID::Native.write_bignum32_array path_in, PATH_IN

    ready_packet = FFI::MemoryPointer.new(INIT_PACKET2.size * 1).write_array_of_char(INIT_PACKET2)
    result = LibHID::Native.hid_set_output_report(interface.to_ptr, path_in, 2, ready_packet, ready_packet.size)
    # LibHID.check_result "Sending init packet", result
  end

  def self.check_result(operation, result)
    if result == :hid_ret_success
      puts "#{operation}... success"
    else
      raise "#{operation} failed with #{result}"
    end
  end

  class Interface
    include Colorize

    def initialize
      @buffer = FFI::Buffer.new :char, BUF_SIZE
      @remaining = 0
      @position = 1
    end

    def initialize!
      WMR.check_result "Initilizing device", LibHID::Native.hid_init

      interface_ptr = LibHID::Native.hid_new_HIDInterface
      @native_interface = LibHID::Native::HIDInterface.new(interface_ptr)

      matcher_ptr = FFI::MemoryPointer.new LibHID::Native::HIDInterfaceMatcher.size
      matcher = LibHID::Native::HIDInterfaceMatcher.new(matcher_ptr)

      matcher[:vendor_id] = WMR100_VENDOR_ID
      matcher[:product_id] = WMR100_PRODUCT_ID

      WMR.check_result "Opening device", LibHID::Native.hid_force_open(interface_ptr, 0, matcher_ptr, RETRIES)

      WMR.send_init_packet(@native_interface)
      WMR.send_ready_packet(@native_interface)

      puts "Found on USB: #{@native_interface[:id]}"
    end

    def inspect_data(data_array)
      pretty = data_array.map do |byte|
        if byte.nil?
          red("nil")
        else
          text = byte.to_s(16).rjust(2, '0')

          case text
          when "ff"
            yellow(text)
          when "01"
            blue(text)
          when "42"
            green(text)
          else
            text
          end
        end
      end

      puts pretty.compact.join(' ')
    end

    def read_packet
      LibHID::Native.hid_interrupt_read(@native_interface.to_ptr, USB_ENDPOINT_IN + 1, @buffer, RECV_PACKET_LEN, 0)

      @position = 1
      @remaining = [@buffer.get_bytes(0, 1)[0].to_i, 7].min
    end

    def read_byte
      read_packet while @remaining.zero? 

      byte = @buffer.get_bytes(@position, 1)[0].to_i
      @position += 1
      @remaining -= 1

      byte
    end

    def read_bytes(length)
      1.upto(length).map {read_byte}
    end

    def valid_checksum?(data)
      length = data.size

      calc = (0...(length-2)).inject(0) { |sum, i| sum += data[i] }
      checksum = data[length-2] + (data[length-1] << 8)

      calc == checksum
    end

    def read_data
      # search for 0xff
      byte = read_byte while byte != 0xff 

      # search for not 0xff
      byte = read_byte while byte == 0xff 

      unk1 = byte
      type = read_byte

      type_name = TYPES[type]
      raise "Unknown type" unless type_name

      raw_data = [unk1, type].push(*read_bytes(SIZES[type_name]))
      raise "Bad checksum" unless valid_checksum?(raw_data)

      data = send("handle_#{type_name}", raw_data)

      yield type_name, data
    rescue => e
      $stderr.puts e.message

      yield :unknown, nil
    ensure
      WMR.send_ready_packet(@native_interface)
    end

    def handle_temp(data)
      sensor = data[2] & 0x0f;
      st = data[2] >> 4;
      smiley = st >> 2;
      trend = st & 0x03;

      smiley_text = SMILIES[smiley] if smiley <= 3
      trend_text = TRENDS[trend] if trend <= 2

      celsius = (data[3] + ((data[4] & 0x0f) << 8)) / 10.0
      celsius = ((data[4] >> 4) == 0x8) ? -celsius : celsius
      fahrenheit = celsius * 9.0/5.0 + 32

      humidity = data[5]

      dewpoint = (data[6] + ((data[7] & 0x0f) << 8)) / 10.0
      dewpoint = -dewpoint if (data[7] >> 4) == 0x8

      {
        :sensor => sensor,
        :fahrenheit => fahrenheit,
        :celsius => celsius,
        :smiley => smiley_text,
        :trend => trend_text,
        :dewpoint => dewpoint,
        :humidity => humidity
      }
    end

    def handle_clock(data)
      power = data[0] >> 4;
      powered = power >> 3;
      battery = (power & 0x4) >> 2;
      rf = (power & 0x2) >> 1;
      level = power & 0x1;

      minute = data[4];
      hour = data[5];
      day = data[6];
      month = data[7];
      year = data[8] + 2000;

      {
        :time => Time.mktime(year, month, day, hour, minute), 
        :powered => powered,
        :rf => rf,
        :battery => battery,
        :level => level
      }
    end

    def cleanup
      LibHID::Native.hid_close(@native_interface)
      LibHID::Native.hid_delete_HIDInterface(@native_interface)
      LibHID::Native.hid_cleanup
    end
  end
end

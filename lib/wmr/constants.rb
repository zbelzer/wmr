module WMR
  WMR100_VENDOR_ID = 0x0fde
  WMR100_PRODUCT_ID = 0xca01

  RECV_PACKET_LEN   = 8
  BUF_SIZE = 255
  PATHLEN = 2
  PATH_IN  = [ 0xff000001, 0xff000001 ]
  PATH_OUT = [ 0xff000001, 0xff000002 ]
  INIT_PACKET1 = [ 0x20, 0x00, 0x08, 0x01, 0x00, 0x00, 0x00, 0x00 ]
  INIT_PACKET2 = [ 0x01, 0xd0, 0x08, 0x01, 0x00, 0x00, 0x00, 0x00 ]
  USB_ENDPOINT_IN	= 0x80
  USB_ENDPOINT_OUT = 0x00

  RETRIES = 10
  SMILIES = [ "  ", ":D", ":(", ":|" ]
  TRENDS = [ "-", "U", "D" ]

  TYPES = {
    0x41 => :rain,
    0x42 => :temp,
    0x44 => :water,
    0x46 => :pressure,
    0x47 => :uv,
    0x48 => :wind,
    0x60 => :clock
  }

  SIZES = {
    :rain => 15,
    :temp => 10,
    :water => 5,
    :pressure => 6,
    :uv => 3,
    :wind => 9,
    :clock => 10
  }
end

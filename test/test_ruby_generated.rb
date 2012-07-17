require "ruby_generated"
require "stringio"
require "hex_string"

class TestSerialize < TestSerialize_Base
end

sio = StringIO.new(String.new())
sr = XDRUtils::XDRSerializer.new(sio)

test = TestSerialize.new()
test.serialize(sr)
serialized = sio.string()
#~ hx = serialized.to_hex_string(false)
#~ puts("hex = #{hx}")

mio = StringIO.new(serialized)
mt = XDRUtils::XDRMaterializer.new(mio)

test2 = TestSerialize.new()
test2.int1 = 0
test2.uint2 = 0
test2.int3 = 0
test2.uint4 = 0
test2.S=""
test2.A=[]

test2.materialize(mt)

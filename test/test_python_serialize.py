# Example serializer/materializer base class
require "stringio"
require "xdr_serializer"

class TestSerialize_Base
  attr_accessor :int1, :uint2, :int3, :uint4, :S, :A

  def initialize
    @int1 = -1  # int
    @uint2 = 1  # uint
    @int3 = 2   # int32
    @uint4 = 3  # uint32
    @S = "Hello"
    @A = [10]   # Array[int]
  end

  def serialize(sr)
    sr.int32(@int1)
    sr.uint32(@uint2)
    sr.int32(@int3)
    sr.uint32(@uint4)
    sr.string(@S)
    sr.array(@A, sr.int32_lambda)
  end

  def materialize(mt)
    @int1 = mt.int32()
    @uint2 = mt.uint32()
    @int3 = mt.int32()
    @uint4 = mt.uint32()
    @S = mt.string()
    @A = mt.array(mt.int32_lambda)
  end

  def sizeneeded
    cnt = 0
    cnt+=8              # int1
    cnt+=8              # uint2
    cnt+=4              # int3
    cnt+=4              # uint4
    cnt+=4+S.length() + (4-S.length()%4)     # S
    cnt+=4+A.length()*4 # A
    return cnt
  end

end

class TestSerialize < TestSerialize_Base
end

1000.times{|i|
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
}


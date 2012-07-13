# Example serializer/materializer base class
require "xdr"
require "stringio"
require "hex_string"
include HexString

class XDRSerializer < XDR::Writer

  attr_accessor :int32_lambda
  def initialize(io)
    @io = io
    @int32_lambda = lambda {|v| int32(v)}
    @uint32_lambda = lambda {|v| uint32(v)}
    @int64_lambda = lambda {|v| int64(v)}
    @uint64_lambda = lambda {|v| uint64(v)}
    @float32_lambda = lambda {|v| float32(v)}
    @float64_lambda = lambda {|v| float64(v)}
  end

  def array(a, f)
    l = a.length()
    uint32(l)
    a.each{|e| f.call(e) }
    return l
  end
end

class XDRMaterializer < XDR::Reader

  def initialize(io)
    @io = io
    @int32_lambda = lambda {|v| int32()}
    @uint32_lambda = lambda {|v| uint32()}
    @int64_lambda = lambda {|v| int64()}
    @uint64_lambda = lambda {|v| uint64()}
    @float32_lambda = lambda {|v| float32()}
    @float64_lambda = lambda {|v| float64()}
  end

  def array(a, f)
    a = Array.new()
    l = uint32()
    l.times {|i| a.push(f()) }
    return a
  end
end


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

  def serialize(serializer)
    serializer.int32(@int1)
    serializer.uint32(@uint2)
    serializer.int32(@int3)
    serializer.uint32(@uint4)
    serializer.string(@S)
    serializer.array(@A, serializer.int32_lambda)
  end

  def materialize(materializer)
    @int1 = materializer.int32()
    @uint2 = materializer.uint32()
    @int3 = materializer.int32()
    @uint4 = materializer.uint32()
    @S = materializer.string()
    @A = materializer.array(materializer.int32_lambda)
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

sio = StringIO.new(String.new())
S = XDRSerializer.new(sio)

test = TestSerialize.new()
test.serialize(S)
hx = sio.string().to_hex_string(false)
puts("hex = #{hx}")


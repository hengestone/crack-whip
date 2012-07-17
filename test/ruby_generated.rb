# Serializable/Materializable base class autogenerated by RubyClassGenerator
# 2012-6-17 14:47:59 DST

require "xdr_serializer"

#------------------------------------------------------------------------------
class TestSerialize_Base
  attr_accessor :int1, :uint2, :int3, :uint4, :S, :A

  def initialize
    @int1 = -1
    @uint2 = 1
    @int3 = 2
    @uint4 = 3
    @S = "Hello"
    @A = [10]
  end

  def serialize(sr)
    sr.int(@int1);
    sr.uint(@uint2);
    sr.int32(@int3);
    sr.uint32(@uint4);
    sr.string(@S);
    sr.array(@A, sr.int_lambda)
  end

  def sizeNeeded()
    cnt = 0;
    cnt += INT_SIZE # int1
    cnt += INT_SIZE # uint2
    cnt += 4 # int3
    cnt += 4 # uint4
    cnt += S.length() + (4 - (S.length())%4) # S
    cnt += A.length()*INT_SIZE + (4 - (A.length()*INT_SIZE)%4) # A
    return cnt
  end

  def materialize(m)
    @int1 = m.int()
    @uint2 = m.uint()
    @int3 = m.int32()
    @uint4 = m.uint32()
    @S = m.string()
    @A = m.array(m.int_lambda, nil)
  end
end

#------------------------------------------------------------------------------
class TestSerializeContainer_Base
  attr_accessor :T

  def initialize
    @T = nil
  end

  def serialize(sr)
    T.serialize(sr);
  end

  def sizeNeeded()
    cnt = 0;
    cnt += T.sizeNeeded() # T
    return cnt
  end

  def materialize(m)
    @T.materialize(m)
  end
end

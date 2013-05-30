# Serializable/Materializable base class autogenerated by RubyClassGenerator
# 2013-05-29 22:03:30 DST

require "xdr_serializer"

#------------------------------------------------------------------------------
class testSerialize_Base
  attr_accessor :int1, :uint2, :int3, :uint4, :S, :A

  def initialize
    @__id = 0x33a98818
    @int1 = -1
    @uint2 = 1
    @int3 = 2
    @uint4 = 3
    @S = "Hello"
    @A = [10]
  end

  def getId
    return @__id
  end

  def serialize(sr, name)
    sr.uint32(@__id, "__whipMessageId")
    sr.int(@int1);
    sr.uint(@uint2);
    sr.int32(@int3);
    sr.uint32(@uint4);
    sr.string(@S);
    sr.array(@A, sr.int_lambda)
  end

  def sizeNeeded()
    cnt = 4;
    cnt += INT_SIZE # int1
    cnt += INT_SIZE # uint2
    cnt += 4 # int3
    cnt += 4 # uint4
    cnt += S.length() + (4 - (S.length())%4) # S
    cnt += A.length()*INT_SIZE + (4 - (A.length()*INT_SIZE)%4) # A
    return cnt
  end

  def materialize(mt)
    __new_id=mt.uint32("__whipMessageId")
    raise 'message id mismatch for TestSerialize, got #{__new_id}, expected #{@__id}' if __new_id != @__id
    @int1 = mt.int()
    @uint2 = mt.uint()
    @int3 = mt.int32()
    @uint4 = mt.uint32()
    @S = mt.string()
    @A = mt.array(mt.int_lambda, nil)
  end
end

#------------------------------------------------------------------------------
class testSerializeContainer_Base
  attr_accessor :T

  def initialize
    @__id = 0x6f42935f
    @T = nil
  end

  def getId
    return @__id
  end

  def serialize(sr, name)
    sr.uint32(@__id, "__whipMessageId")
    T.serialize(sr, mname);
  end

  def sizeNeeded()
    cnt = 4;
    cnt += T.sizeNeeded() # T
    return cnt
  end

  def materialize(mt)
    __new_id=mt.uint32("__whipMessageId")
    raise 'message id mismatch for TestSerializeContainer, got #{__new_id}, expected #{@__id}' if __new_id != @__id
    @T.materialize(m, T)
  end
end


# Example serializer/materializer base class
require "xdr"

module XDRUtils

  class XDRSerializer < XDR::Writer
    attr_accessor :int32_lambda, :uint32_lambda, :int64_lambda,
      :uint64_lambda, :float32_lambda, :float64_lambda, :string_lambda,
      :int_lambda, :uint_lambda

    def int(v)
      int32(v)
    end  

    def uint(v)
      uint32(v)
    end  

    def initialize(io)
      @io = io
      @int_lambda = lambda {|v| int32(v)}
      @uint_lambda = lambda {|v| uint32(v)}
      @int32_lambda = lambda {|v| int32(v)}
      @uint32_lambda = lambda {|v| uint32(v)}
      @int64_lambda = lambda {|v| int64(v)}
      @uint64_lambda = lambda {|v| uint64(v)}
      @float32_lambda = lambda {|v| float32(v)}
      @float64_lambda = lambda {|v| float64(v)}
      @string_lambda = lambda {|v| string(v)}
    end

    def array(a, f=nil)
      l = a.length()
      uint32(l)
      if f.nil?
        a.each{|e| e.serialize(self) }
      else
        a.each{|e| f.call(e) }
      end # if
      return l
    end # def

  end # class

  class XDRMaterializer < XDR::Reader
    attr_accessor :int32_lambda, :uint32_lambda, :int64_lambda,
      :uint64_lambda, :float32_lambda, :float64_lambda, :string_lambda,
      :int_lambda, :uint_lambda

    def int()
      int32()
    end  

    def uint()
      uint32()
    end  

    def initialize(io)
      @io = io
      @int_lambda = lambda {int32()}
      @uint_lambda = lambda {uint32()}
      @int32_lambda = lambda {int32()}
      @uint32_lambda = lambda {uint32()}
      @int64_lambda = lambda {int64()}
      @uint64_lambda = lambda {uint64()}
      @float32_lambda = lambda {float32()}
      @float64_lambda = lambda {float64()}
      @string_lambda = lambda {string()}
    end

    def array(f, cl=nil)
      a = Array.new()
      l = uint32()
      if f.nil? and !cl.nil?
        l.times { |i|
          o = cl.new()
          o.deserialize(self)
          a.push(o)
        }
      else
        l.times {|i| a.push(f.call()) }
      end
      return a
    end

  end

end

# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.
require 'sequence'
require 'sequence/indexed'

class Sequence
  class OfHash < OfArray
    def initialize(hash,exceptions=[],include_default=false,modifiable=false)
      @hash=hash
      hash=hash.dup
      exceptions.each{|exc| hash.delete exc }
      @data=hash.inject([]){|l,pair| l+pair}
      @data<<hash.default if include_default
      @data.freeze unless modifiable
    end  
    
    def modify(*args)
      repldata=args.pop
      start,len,only1=_parse_slice_args(*args)
      len==1 or raise "scalar modifications to hashes only!"
      if @data.size.%(2).nonzero? and @data.size.-(1)==start
        @hash.default=repldata.first
      elsif start.%(2).zero? #key 
        @hash[repldata.first]=@hash.delete @data[start]
      else #value
        @hash[@data[start-1]]=repldata.first
      end
      @data[first]=repldata.first
      repldata
    end
  end
end

class Hash
  def to_sequence(include_default=false)
    Sequence::OfHash.new(self,include_default)
  end
end
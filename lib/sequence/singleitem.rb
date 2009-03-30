# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.
require 'sequence'

class Sequence
  #represnts a seq over a single item
  class SingleItem < Sequence
    include ArrayLike
    def initialize(obj)
      @obj=obj
      @eof=false
    end
    
    def read1
      result=readahead1
      @eof=true
      result
    end
    
    def readahead1
      @obj unless @eof
    end
    
    def size; 1 end
    
    def eof?; @eof end
    
    def read(len)
      @eof and return []
      @eof=true
      return [@obj]
    end
    
    def begin!
      @eof=false
    end
    
    def end!
      @eof=true
    end
    
    def pos
      @eof ? 1 : 0
    end
    
    def _pos=(pos)
      @eof=pos.nonzero?
    end
  end
end
# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.
require 'sequence'
class Sequence
  # define #read in terms of #data and @pos.
  # #data must support #[]
  class UseData < Sequence
    
    def read(len)
      result=readahead(len)
      @pos+=result.size
      result
    end

    def readback(len)
      result=readbehind(len)
      @pos-=result.size
      result
    end

    def readahead(len)
      @data[@pos,len] 
    end

    def readbehind(len)
      len>@pos and len=@pos
      @data[@pos-len,len] 
    end
    
    
    def size; data.size end
    def_delegators :@data, :<<

  end
end
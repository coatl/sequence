# Copyright (C) 2006, 2011  Caleb Clausen
# Distributed under the terms of Ruby's license.
require 'sequence'
require 'sequence/usedata'

class Sequence
  class SubSeq < Sequence
    def initialize(seq, first,len)
      assert first
      first+len-1>=seq.size and len=seq.size-first
      @data=seq
      @pos=0
      @first,@size=first,len
      extend seq.like

      #ask for notifications on the parent seq...
      @data.on_change_notify self
      assert @first
      #p [:init,__id__]
    end

    def change_notification data,first,oldsize,newsize
      assert @data==data 
      old_first=@first
      old_size=@size
      @pos=(_adjust_pos_on_change @first+@pos,first,oldsize,newsize)-@first
      @size=(_adjust_pos_on_change @first+@size,first,oldsize,newsize)-@first
      @first=_adjust_pos_on_change @first,first,oldsize,newsize
      assert @first
      #p [:cn, __id__]
      
      notify_change(self, first-@first, oldsize, newsize)
    end

    def offset; @first end

    def readahead(len)
        eof? and return new_data
        len>rest=rest_size and len=rest
        @data[@pos+offset,len]
    end

    def readbehind(len)
      @pos.zero? and return new_data
      @pos>=len or len=@pos
      @data[@pos+offset-len,len] 
    end
    
    def read(len)
      result=readahead(len)
      move result.size
      result
    end

    def readback(len)
      result=readbehind(len)
      move( -result.size )
      result
    end

    def eof?
      @pos>=@size
    end

    attr_reader :size,:pos
    
    def _pos=newp
      @pos=newp
    end
    
    def_delegators :@data, :data_class, :new_data

    attr :data

    def subseq *args
      #p [:subseq, __id__]
      first,len,only1=_parse_slice_args( *args)
      SubSeq.new(@data,@first+first,len)
    end
    
    def modify(*args)
      data=args.pop
      first,len,only1=_parse_slice_args( *args)
      first+=@first
      only1 ? @data.modify(first,data) : @data.modify(first,len,data)
    end

    
    def closed?
      super or @data.closed?
    end

  end
  SubSequence=SubSeq
end

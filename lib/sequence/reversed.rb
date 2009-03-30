# $Id$
# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.

require 'sequence'

class Sequence
class Circular< Sequence; end #forward decl
# This class can be used to reverse the direction of operations on a given
# sequence.  It has a separate position, independant of the original sequence's.
class Reversed < Sequence
    #when reversed and circular, always put the Circular outermost.
   class<<self
     alias new__no_circular new
     def new(sequence,pos=0)
       if Circular===sequence
         Circular.new(new__no_circular(sequence.data,pos))
       else
         new__no_circular(sequence,pos)
       end
     end
   end


    def initialize(sequence,pos=0)
        @seq = sequence
        @pos=pos
        @size=sequence.size
        extend @seq.like
        
        @seq.on_change_notify self
    end
    
    def translate_pos(pos)
      @size-pos
    end
    
    def change_notification(cu,first,oldsize,newsize)
#      Process.kill("INT",0)
      assert cu==@seq
#      @pos =translate_pos cu._adjust_pos_on_change(translate_pos(pos), first,oldsize,newsize)
      first=translate_pos(first+oldsize)
      @pos =_adjust_pos_on_change((pos), first,oldsize,newsize)
      @size+=newsize-oldsize
      assert @size==@seq.size
      notify_change(self, first,oldsize,newsize)
    end
    
    # :stopdoc:
    def new_data
        @seq.new_data
    end
=begin ***
    def read1after
        @seq.read1before
    end
    def read1before
        @seq.read1after
    end

    def skip1next
        @seq.skip1prev
    end
    def skip1prev
        @seq.skip1next
    end
    def skip1after
        @seq.skip1before
    end
    def skip1before
        @seq.skip1after
    end
    def delete1after
        v0 = @seq.delete1before
        v0 && @positions && _adjust_delete
        v0
    end
    def delete1before
        v0 = @seq.delete1after
        v0 && @positions && _adjust_delete
        v0
    end
    def delete1after?
        v0 = @seq.delete1before?
        v0.nil? || @positions && _adjust_delete
        v0
    end
    def delete1before?
        v0 = @seq.delete1after?
        v0.nil? || @positions && _adjust_delete
        v0
    end
    def write1next(v)
        @seq.write1prev(v)
    end
    def write1prev(v)
        @seq.write1next(v)
    end
    def write1after(v)
        @seq.write1before(v)
    end
    def write1before(v)
        @seq.write1after(v)
    end
    def write1next?(v)
        @seq.write1prev?(v)
    end
    def write1prev?(v)
        @seq.write1next?(v)
    end
    def write1after?(v)
        @seq.write1before?(v)
    end
    def write1before?(v)
        @seq.write1after?(v)
    end
    def insert1before(v)
        @positions && _adjust_insert
        @seq.insert1after(v)
    end
    def insert1after(v)
        @positions && _adjust_insert
        @seq.insert1before(v)
    end
    def scan1next(v)
        @seq.scan1prev(v)
    end
    def scan1prev(v)
        @seq.scan1next(v)
    end
    def modify1next(lookup)
        @seq.modify1prev(lookup)
    end
    def modify1prev(lookup)
        @seq.modify1next(lookup)
    end
=end
    attr_reader :pos,:size
    def _pos=(pos)
      @pos=pos
    end
    
    def read(len)
      assert @pos>=0
      assert @size>=@pos
      start =@size-@pos-len
      start<0 and start=0
      result=@seq[start...@size-@pos] or return ""
      @pos+=result.size
      result.reverse
    end
    
    def modify(*args)
      first,len,only1=_parse_slice_args( *args[0..-2] )
 #     puts "first=#{first}, len=#{len}"
      first=@size-first-len
      @seq.modify first, len, args.last.reverse
      #notify_change(self,first,len,args.last.size)  #?? is this a good idea?
      args.last
    end
    
    def eof?
      @pos>=@size
    end
    
    def closed?
      super or @seq.closed?
    end
    
    def reverse
      @seq.position(0)
    end



    # :startdoc:
end
end



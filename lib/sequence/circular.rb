# $Id$
# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.

require 'sequence'

class Sequence
# This Sequence class is used to represent a circular buffer.  You can think of
# this as having no beginning/end or the current location is always both at the
# beginning/end.  Because of the circular nature, the methods
# #scan_until, #modify, 
# #each, #collect!, and #map!
# are not defined.
class Circular < Sequence
    # Create a circular sequence from a normal finite one.
    def initialize(sequence,pos=sequence.pos)
        @seq = sequence
        @pos=pos
        @size=sequence.size
        extend sequence.like
        
        @seq.on_change_notify self
    end
    
    #the default _parse_slice_args isn't forgiving enough about large 
    #(positive or negative) indexes
    def _normalize_pos pos, size=nil
      pos
    end
    
    def change_notification(cu,first,oldsize,newsize)
      assert(cu.equal?( @seq ))
      @pos =_adjust_pos_on_change(@pos, first,oldsize,newsize)
      @size+=newsize-oldsize
      assert @size==@seq.size
      notify_change(self,first,oldsize,newsize) 
    end
    
=begin
    def _adjust_delete(len=1,reverse=false)
        pos = _pos(false)
        ret = nil
        @positions.each { |p| ret = p.__send__(:_deletion,pos,len,reverse,ret) }
    end
    def _adjust_insert(len=1)
        pos = _pos(false)
        ret = nil
        @positions.each { |p| ret = p.__send__(:_insertion,pos,len,ret) }
    end
=end
    attr_reader :pos,:size
    def _pos=(pos)
      #pos=0 if pos>=size
      @pos=pos
    end
    public

    # :stopdoc:
    def new_data
        @seq.new_data
    end
=begin **    
    def read1next
        v0 = @seq.read1next
        v0.nil? && @seq.move!(true) && (v0 = @seq.read1next)
        v0
    end
    def read1prev
        v0 = @seq.read1prev
        v0.nil? && @seq.move!(false) && (v0 = @seq.read1prev)
        v0
    end
    def read1after
        v0 = @seq.read1after
        v0.nil? && begin! && (v0 = @seq.read1after)
        v0
    end
    def read1before
        v0 = @seq.read1before
        v0.nil? && @seq.move!(false) && (v0 = @seq.read1before)
        v0
    end
    def skip1next
        @seq.skip1next || @seq.skip!(true) && @seq.skip1next
    end
    def skip1prev
        @seq.skip1prev || @seq.skip!(false) && @seq.skip1prev
    end
    def skip1after
        @seq.skip1after || @seq.skip!(true) && @seq.skip1after
    end
    def skip1before
        @seq.skip1before || @seq.skip!(false) && @seq.skip1before
    end
    def delete1after
        v0 = @seq.delete1after || @seq.skip!(true) && @seq.delete1after
        v0.nil? || @positions && _adjust_delete
        v0
    end
    def delete1before
        v0 = @seq.delete1before || @seq.skip!(false) && @seq.delete1before
        v0.nil? || @positions && _adjust_delete
        v0
    end
    def delete1after?
        v0 = @seq.delete1after?
        v0.nil? && @seq.skip!(true) && (v0 = @seq.delete1after?)
        v0.nil? || @positions && _adjust_delete
        v0
    end
    def delete1before?
        v0 = @seq.delete1before?
        v0.nil? && @seq.skip!(false) && (v0 = @seq.delete1before?)
        v0.nil? || @positions && _adjust_delete
        v0
    end
    def write1next(v)
        @seq.write1next(v) || @seq.skip!(true) && @seq.write1next(v)
    end
    def write1prev(v)
        @seq.write1prev(v) || @seq.skip!(false) && @seq.write1prev(v)
    end
    def write1after(v)
        @seq.write1after(v) || @seq.skip!(true) && @seq.write1after(v)
    end
    def write1before(v)
        @seq.write1before(v) || @seq.skip!(false) && @seq.write1before(v)
    end
    def write1next?(v)
        v0 = @seq.write1next?(v)
        v0.nil? && @seq.skip!(true) && (v0 = @seq.write1next?(v))
        v0
    end
    def write1prev?(v)
        v0 = @seq.write1prev?(v)
        v0.nil? && @seq.skip!(false) && (v0 = @seq.write1prev?(v))
        v0
    end
    def write1after?(v)
        v0 = @seq.write1after?(v)
        v0.nil? && @seq.skip!(true) && (v0 = @seq.write1after?(v))
        v0
    end
    def write1before?(v)
        v0 = @seq.write1before?(v)
        v0.nil? && @seq.skip!(false) && (v0 = @seq.write1before?(v))
        v0
    end
    def insert1before(v)
        @positions && _adjust_insert
        @seq.insert1before(v)
    end
    def insert1after(v)
        @positions && _adjust_insert
        @seq.insert1after(v)
    end
    def scan1next(v)
        v0 = read1next
        (v0.nil? || v==v0) ? v0 : (skip1prev;nil)
    end
    def scan1prev(v)
        v0 = read1prev
        (v0.nil? || v==v0) ? v0 : (skip1next;nil)
    end
    def modify1next(r)
        v0 = read1after
        (v0.nil? || (v = r[v0]).nil?) ? nil : (write1next!(v);v0)
    end
    def modify1prev(r)
        v0 = read1before
        (v0.nil? || (v = r[v0]).nil?) ? nil : (write1prev!(v);v0)
    end
=end
    # :startdoc:
    # read over one pass of the data to return where you started
    def read!(reverse=false)
      unless reverse
        read(size)
      else
        readback(-size)
      end
    end
    # skip over one pass of the data to return where you started
    def move!(reverse=false)
        size
    end
    alias end! begin!
    alias end begin
    # Compare to +other+.  
    def <=>(other)
        position?(other) and pos<=>other.pos
    end

=begin ***
    # insert an element before the position and return self
    def << (value)
        insert1before(value)
        self
    end
    # insert an element after the position and return self
    def >> (value)
        insert1after(value)
        self
    end
=end
    # :stopdoc:

    def data
      @seq
    end
    
    def each
      po=position
      yield read1 until self==position
      po.close
    end
    
    def eof?; false end
    
    def readahead(len)
      result=@seq[@pos%size,len]
      len-=result.size
      len.zero? and return result
      loops=len/size
      
      result+=@seq[0...size]*loops if loops.nonzero?
      
      len%=size
      
      len.zero? and return result
      
      result+=@seq[0,len]
    end

    def read len
      result=readahead len
      move len
      result
    end
    
    def modify(*args)
      data=args.last
      first,len,only1=_parse_slice_args(*args[0...-1])
      first %= size
      
      len>size and raise( ArgumentError, "dst len too long")
      first+len>size and raise( ArgumentError, "wraparound modify in circular")

      @seq.modify(*args)
    end
    
    #when reversed and circular, always put the Circular outermost.
    def reverse
      Circular.new @seq.reverse
    end
    
    def nearbegin(len,at=pos) 
      false
    end
    
    def nearend(len,at=pos)
      false
    end
    
    def closed?
      super or @seq.closed?
    end
end
end




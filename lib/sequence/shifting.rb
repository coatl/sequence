# $Id$
# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.

require 'sequence'

class Sequence
#a primary sequence (presumably unidirectional) with a secondary sequence
#as backup. the primary is traversed in the forward direcion only. the 
#secondary holds a copy of data as it comes from the primary sequence. the
#position can be independantly changed to any location; if before the
#current position of the primary sequence, the secondary sequence is used
#instead. all writes go to the secondary sequence.


class Shifting < Sequence
    def initialize(seq,data= Sequence::Indexed.new(seq.new_data))
        @seq=seq #primary
        @data = data   #secondary
        @offset=@seq.pos
        
        extend @seq.like
        
        @seq.on_change_notify self
    end
    # :stopdoc:
    def new_data
        @data.new_data
    end
    
    def change_notification(cu,first,oldsize,newsize)
      assert @seq==cu
      
      if first<=@offset
        if first+oldsize>=@offset
          offset=first
        end
        @offset-=oldsize-newsize
      end 
      
      #modify @data (shift buffer) to suit
      if first<@offset
        @data.prepend @seq[first...@offset]
        @offset=first
      elsif first<@data.size+@offset  #if change within already shifted data
        @data[first-@offset,oldsize]= @seq[first,newsize]  
      end
      
      notify_change(self,first,oldsize,newsize)
    end
=begin ***
    protected
    def _delete1after?
        @pos.nonzero? && (@pos0 -= 1) && @data.slice!(0)
    end
    def _delete1before?
        @pos==@data.size ? nil : @data.slice!(-1)
    end
    def _insert1before(v)
        @data << v
        true
    end
    def _insert1after(v)
        @data[0,0] = (@data.class.new << v)
        @pos += 1
        true
    end
=end
protected
   def history_mode?
     !@data.eof?
   end

public
   def read(len)
     assert oldpos=pos
     if history_mode?
       rest=@seq.pos-pos
       len<=rest and return @data.read(len)
       @data.append @seq.read(len-rest)
     else
       assert @data.pos+@offset==@seq.pos
       @data.append @seq.read(len)
     end
     result=@data.read!
#     assert pos==oldpos+len || pos==size
     return result
   end
 
   def _pos= x; 
     assert @data.empty?|| (0..@data.size)===pos-@offset
     #assert @data.size+@offset==@seq.pos
     if @data.empty?
       diff=x-@offset
       @data<<
         if diff<0
           @offset=x
           diff=-diff
           @seq[x,diff] rescue
             case data_class
             when ::Array:  [nil]
             when ::String: "\0"
             else fail
             end*diff
        
         else #diff>=0
           @seq.read(diff)
         end
     
       @data.pos=x-@offset
       assert @data.size+@offset==@seq.pos
       assert( (0..@data.size)===x-@offset )
     elsif x<@offset
       offset=@offset
       @offset=x
       @data.prepend((
         @seq[x...offset] rescue
         case data_class
         when ::Array:  [nil]
         when ::String: "\0"
         else fail
         end*(offset-x)
       ))
#       assert @data.size+@offset==@seq.pos
       assert( (0..@data.size)===x-@offset )
     elsif x>@data.size+@offset
#       assert @seq.pos==@data.size+@offset
       @data<<@seq.read(x-@data.size-@offset)
       @data.pos=@data.size
       #assert @data.size+@offset==@seq.pos
       assert( (0..@data.size)===x-@offset )
     else
       @data.pos=x-@offset
       #assert @data.size+@offset==@seq.pos
       assert( (0..@data.size)===x-@offset )
     end
     #assert @data.size+@offset==@seq.pos
     assert( (0..@data.size)===x-@offset )
#     assert(pos==x || pos==size)
     x
   end
   
   def modify *args
     newvals=args.pop
     first,len,only1=_parse_slice_args( *args )
     only1 and newvals=new_data<<newvals

     assert @data.size+@offset==@seq.pos

     oldpos=pos

     if @data.empty?
       @offset=first
       @data<<newvals
       @data.pos=_adjust_pos_on_change(oldpos, first, len, newvals.size)-@offset
       #assert @data.size+@offset==@seq.pos
     else
       #if first...first+len outside of @data, read it into @data first
       oldpos=pos
       self._pos=first
       self._pos=first+len
       self._pos=oldpos #then revert to orig position
     
       assert( (0...@data.size)===first-@offset )
       assert( (0...@data.size)===first+len-@offset )
       @data.modify first-@offset,len,newvals
       #assert @data.size+@offset==@seq.pos
     end
     notify_change(self,first,len,newvals.size)
     
     #assert @data.size+@offset==@seq.pos

     newvals
   end

   def pos; @data.pos+@offset end
  
   def_delegators :@seq, :size

   def eof?; @data.eof? and @seq.eof? end
    # :startdoc:
    
   def closed?
      super or @seq.closed?
   end
    
end
end



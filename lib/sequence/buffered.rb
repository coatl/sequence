# $Id$
# Copyright (C) 2006, 2011  Caleb Clausen
# Distributed under the terms of Ruby's license.

require 'sequence'
#require 'sequence/split'

class Sequence
# This class gives unidirectional sequences (i.e. IO pipes) some
# bidirectional capabilities.  An input sequence (or input IO) and/or an output
# sequence (or output IO)
# can be specified.  The #position, #position?, and #position! methods are
# used to control buffering.  Full sequence capability (limited by the size of the buffer
# sequence) is accessible starting from the first #position.  When the end of
# the buffer is reached more data is read from the input sequence (if not nil) .  When no
# #position is outstanding, everything before the buffer sequence is written
# to the output sequence (if not nil).  If the sequence is attempted
# to be moved before the buffer, the output sequence is read in reverse (which
# the output sequence may not like).
#how much of that should remain true?
class Buffered < Sequence
    def initialize(input,buffer_size=1024,buffer=nil)
        @input = input
        huh #@input used incorrectly... it should be used kinda like a read-once data store
            #and Buffered should have an independant position
        @buffer_size=buffer_size
        @buffer = buffer||@input.new_data
#        @output_pos = output_pos
        @buffer_pos=@pos=@input.pos
        
        @input.on_change_notify self  
    end
    
    def change_notification
      huh #invalidate (part of) @buffer if it overlaps the changed area
      huh #adjust @buffer_pos as necessary
    end
    
    attr_accessor :buffer_size
    attr :pos
    
    # :stopdoc:
    def new_data
        @input.new_data
    end
    def _default_maxmatchlen; @buffer_size/2 end

    def _pos=(pos)
      if pos<@buffer_pos
        @pos=@input.pos=pos  #could raise exception, if @input doesn't support #pos=
      elsif pos<=@buffer_pos+@buffer.size
        @pos=pos
      else #@pos > buffer_end_pos
        assert @buffer_pos+@buffer.size==@input.pos
        @buffer<<@input.read(pos-@input.pos)
        buffer_begin_ageout!
      end
    end

    def history_mode?(pos=@pos)
      pos<@buffer_pos+@buffer.size
    end
    
    def_delegators :@input, :size

    def crude_read(len)
        assert @buffer_pos+@buffer.size==@input.pos
        result=@input.read(len)
        @buffer<<result
        buffer_begin_ageout!
        result
    end

    def crude_read_before(len)
        assert @buffer_pos+@buffer.size==@input.pos
        result=@input.read(len)
        @buffer.insert(0,*result)
        buffer_end_ageout!
        result
    end

    def read(len)
      if @pos<@buffer_pos
        if @buffer_pos-@pos >= @buffer_size
          @buffer_pos=@pos
          @buffer=new_data
          return crude_read(len)
        else 
          crude_read_before(@buffer_pos-@pos)
          self._pos=@buffer_pos
          
          #fall thru
        end
      end
      
      if history_mode?
        if history_mode?(pos+len-1)
          result=@buffer[@pos-@buffer_pos,len]
          @pos+=len
        else
          result=@buffer[@pos-@buffer.pos..0]
          result<<crude_read(len-result.size)
        end

        result
      else
        crude_read len
      end
    end

    def buffer_begin_ageout!
      diff=@buffer.size-@buffer_size 
      if diff>0 
        @buffer.slice!(0,diff)
        @buffer_pos+=diff
      end
    end
    
    def buffer_end_ageout!
      diff=@buffer.size-@buffer_size 
      if diff>0 
        @buffer.slice!(-diff..-1)
      end
    end

    def modify(*args)
      huh "what does it mean to write to a Buffered?"
      repldata=args.pop
      first,len,only1=_parse_slice_args(*args)
      first<pos-@buffer.size and huh
      result=new_data
      if first<pos
        result=@buffer[huh]
      end
      if first+len>pos
        huh
      end
      huh
    end


    # :startdoc:
end
end



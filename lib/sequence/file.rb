# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.
# $Id$

require 'sequence'
require 'sequence/stringlike'

class Sequence
# This class treats an IO (or StringIO) as an Sequence.  An IO is already
# like an Sequence, but with a differing interface.  
# Actually, we assume that the IO is capable of seeking, so it most likely
# must be a File. 
# delete/insert at arbitrary location is not supported.
class File < Sequence
#    include UseNext
    include StringLike
    def initialize(file,mode="r")

      case file
      when Integer;  file=IO.new(file,mode)
      when String;   file=File.new(file,mode)
      else #do nothing, file is of a right type (we hope) already
      end
      
      @io = file
    end
    # :stopdoc:
    def new_data
        ''
    end
    def data; @io end
    def read1
        @io.getc
    end
=begin ***
    def write1next(v)
        @io.eof? ? nil : (@io.putc(v);true)
    end
    def write1next!(v)
        @io.putc(v)
        true
    end
    def skip1prev
        @io.pos.nonzero? && (@io.seek(-1,::IO::SEEK_CUR);true)
    end
=end
    def readahead1
        v0 = @io.getc
        v0 && @io.ungetc(v0)
        v0
    end
=begin ***
    def write1after!(v)
        @io.putc(v)
        @io.seek(-1,::IO::SEEK_CUR)
        true
    end
    def skip1next
        @io.getc ? true : nil
    end
    def skip1after
        @io.eof? ? nil : true
    end
    def skip1before
        @io.pos.zero? ? nil : true
    end
    def scan1next(v)
        v0 = @io.getc
        (v0.nil? || v==v0) ? v0 : (@io.ungetc(v0);nil)
    end
=end
    def size
      @io.stat.size
    end
    def read(len)
           @io.read(len) or ""
    end
    def readahead(len)
            buffer1 = read(len)
                @io.seek(-buffer1.size,::IO::SEEK_CUR)
        buffer1
    end
    def readback(len)
      result=readbehind(len)
                @io.seek(-result.size,::IO::SEEK_CUR)
      result
    end
    def readbehind(len)
            p = @io.pos
            len>p and len=p
            @io.seek(-len,::IO::SEEK_CUR)
            @io.read(len)
    end
    def read!(reverse=false)
        if reverse                   
            len = @io.pos.nonzero? or return ""
            @io.seek(0, ::IO::SEEK_SET)
            #@io.pos = 0 # BUGGY in v1.8.2
            buffer1 = @io.read(len) || ""
            @io.seek(0, ::IO::SEEK_SET)
        else
            buffer1 = @io.read(nil)
        end
        buffer1
    end
    
    def eof?; @io.eof? end

    def _pos=(p)
        @io.seek(p,::IO::SEEK_SET)
        p
    end
   
    
    def modify(*args)
      data=args.pop
      first,len,only1=_parse_slice_args(*args)
      if first+len==size #working at end of data?
        holding{
          @io.truncate first if len.nonzero?
          goto first
          @io.write data
        }
      elsif len==data.size  #inserted data is same size?
        holding{
          goto first
          @io.write data
        }
      else
        raise ArgumentError,"replace data must be same size or modification must be at very end" 
      end
      notify_change(self,first,len,data.size)
      data
    end
    
    
    
    def append(str)
        Integer===str and str=str.chr
        first=nil
        holding{
          end!
          first=pos
          @io.write str
        }
        notify_change(self,first,0,str.size)      
        self
    end
    
    def close
        @io.close
        super
    end

    def pos;     @io.tell end
    # :startdoc:
end
end

class File
    # convert a File to a seq
    def to_sequence
       Sequence::File.new(self)
    end
end

class StringIO < Data
    # convert an StringIO to a seq
    def to_sequence
       Sequence::File.new(self)
    end
end

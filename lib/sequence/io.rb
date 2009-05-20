# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.
require 'sequence/stringlike'
require 'fcntl'

class Sequence

#external iterator over data in an general IO object (a pipe, console, socket, serial port, or the like).
#For Files, please use Sequence::File instead, as it is more capable.
#This Sequence class can only go forward, and can only read, it cannot write to the data stream. 
#Thus many of Sequence's usual methods will not work with this class.
#At the moment, this even includes #scan and friends, tho I will try to make those work somewhat.
#Also note that this is one of the few Sequence classes that might return less that the amount asked
#for in a read, even if not at the end of file.
#Due to use of nonblocking io, this might not work on windows.
#The value of #size in this sequence continually increases over its lifetime, and it isn't possible to 
#know the final value beforehand. Likewise, #eof? may return false even tho it's destined to return
#true at the same position. This is because the 'other end' may not have closed the IO, even if there's
#no more data to send.
#
#if you need to be able to scan forward and back, consider wrapping the IO in a Buffered or Shifting 
#Sequence.
class IO < Sequence
  include StringLike
  def initialize(io)
    @io=io
    @pos=0
    
    @io.fcntl(::Fcntl::F_SETFL, ::Fcntl::O_NONBLOCK)
    #I gather this won't work on windows....
    
    @fragment=''
  end
  
  attr :pos

  undef pos=, _pos=, position, position?, holding, holding?, holding!, readback, readback1
  undef readahead, readbehind, readahead1, readbehind1, write#, write1
  undef goto, move, move!, subseq, reversed, +, -, succ, pred, begin, end
  undef begin!, end!,  first, last, slice, [], modify, []=


  def size
    #refill fragment if needed
    @fragment=@io.sysread(4096) if @fragment.empty?

    return @pos+@fragment.size 
  end

  def more_data?
    #refill fragment if needed
    @fragment=@io.sysread(4096) if @fragment.empty?
    
    return !eof 
  end
  
  def eof?; 
    @fragment.empty? and #need to be at buffer end
      @io.eof?  
  end
  
  def read len
    if len<= @fragment.size
      @pos+=len
      @fragment.slice! 0,len
    else
      result=@fragment
      len-=@fragment.size
      
      readlen=len
      rem=len%4096
      rem.nonzero? and readlen+=4096-rem
      
      @fragment=@io.sysread(readlen) 
      result+=@fragment.slice!(0,len)
      @pos+=result.size
      result
    end
  end
  
  def match pat
    @fragment.size>=scanbuflen or @fragment<<@io.sysread(4096)
    result=@fragment.match(pat)
    result if result.begin(0).zero?
  end
  
  def _pos=newpos
    newpos<pos and raise ArgumentError
    if newpos<=@pos+@fragment.size
      len=newpos-@pos
      @fragment.slice!(0,len)
      @pos=newpos
    else
      len=newpos-(@pos+@fragment.size)
      len > 10*4096 and raise ArgumentError
      @fragment=''
      tossit=@io.sysread(len)
      @pos=newpos-(len-tossit.size)
    end
  end
end
end

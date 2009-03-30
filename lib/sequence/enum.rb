# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.
require 'thread'
require 'sequence/arraylike'

=begin discussion

Sequence::Enum is pretty much the same thing as Generator from the
ruby standard library, but faster.
(Newer versions of the standard library include an improved 
Generator, which should be about as fast.)

The key insight is to realize that Continuations were used in the 
original because an independant call stack is needed (to run #each 
in), separate from the call stack of the user of Generator. However,
Continuations are only one way to get another call stack; you could 
also use a Thread (plus a Queue, to communicate back the results), 
which doesn't have the same performance problems in ruby.

In order to implement #readahead1, I had to invent Queue#peek,
which tells you what the next element is without taking it from the
Queue.

Actually, I'm using a SizedQueue, not a plain Queue. Otherwise, the
memory used by the queue could grow without bounds.

#begin! was also a small challenge, until I realized that you could 
just restart the Thread. (Hopefully, the enum or block will return
the same results the second time through.)

It's not allowed in Generator, but Sequence::Enum permits you to
pass in both an enum and a block. The results of the
block are passed up once the enum is exhausted.

#<< allows you to
add more items to the Sequence::Enum once it has been created. At first,
this was also aliased to #yield, because I didn't quite realize that
#yield should only be used inside the constructor's block. Once I
straightened out #yield, I decided that adding items after 
construction was a cool feature, so I left the capability in. 

It's clear that this version is faster than the original callcc-
based Generator, but I'm not sure how much. I was unable to run
the relevant benchmark to completion on my machine. Even after reducing 
the number of loops in the test by 10x, the callcc version was 
still taking more than 2 hours. (I don't know how much more because
at that point I grew impatient and gave it the ^C.) My own version
finishes in about a second or less. 

I also found that bumping the queue size up to 400 from the original
32 made about a 4x difference in running time. This implies to me 
that context switches in ruby are rather more expensive than I 
expected.
=end

if true

require 'sequence/generator'

class Sequence
  class Enum < Sequence
    include ArrayLike
  
    def initialize(enum=nil,&block)
      @gen=Generator.new(enum,&block)
    end
    
    def eof?; @gen.end? end
    def pos; @gen.index end
    def begin!; @gen.rewind; 0 end
    
    def each &block
      @gen.dup.each &block
    end
    
    def read len
      return [] if len.zero? or eof?
      result=[]
      begin 
        len.times{ result<<@gen.next }  
      rescue EOFError:
      end 
    
      return result
    end

    def readahead1
      @gen.current
    rescue EOFError:
      return nil
    end

    def read1
      @gen.next
    rescue EOFError:
      return nil
    end
    
    alias size pos
    
    


    %w[pos= _pos= scan scan_until write [] []= 
       holding holding? holding! position
    ].each{|mname| undef_method mname}
  end
end


else


class Queue
 # Retrieves next data from the queue, without pulling it off the queue.
 # If the queue is empty, the calling thread is
 # suspended until data is pushed onto the queue. 
 # If +non_block+ is true, the
 # thread isn't suspended, and an exception is raised.
  def peek(non_block=false)
    raise ThreadError, "queue empty" if non_block and empty?
    Thread.pass while (empty?)
    Thread.critical=true
      result=@que.first
    Thread.critical=false
    result
  end
  
  def read(len)
    Thread.critical=true
      result=@que.slice![0...len]
    Thread.critical=false
    result
  end
end


class Sequence
  class Enum < Sequence
    include ArrayLike
  
    def initialize(enum=[],qsize=400,&block)
      @extras=[]
      @extrasmutex=Mutex.new
      init(enum,qsize,&block)
    end
        
    def init(enum,qsize,&block)
      @block=block
      @pos=0
      @enum=enum
      @q=q=SizedQueue.new(qsize)
      @thread=Thread.new{
        enum.each{|item| q<<item }
        block[self] if block
        i=0
        while i<@extras.size
          q.push @extrasmutex.synchronize { @extras[i] }
          i+=1
        end
      }
    end
        
    #should only be called from inside constructor's block
    def yield(item)
      @q.push item    
    end

    def <<(item)
      @extrasmutex.synchronize { @extras<<item }
    end

    def begin!
      @thread.kill
      init(@enum,@q.max,&@block)
      0
    end
    
    def readahead1
      current
    rescue EOFError:
      return nil
    end

    def read1
      self.next
    rescue EOFError:
      return nil
    end
    
    def current
      raise EOFError if eof?
      @q.peek
    rescue ThreadError:
      raise EOFError
    end

    def next
      result=@q.pop
      raise EOFError if !result && eof?
      @pos+=1
      result
    rescue ThreadError:
      raise EOFError
    end
    
    def read(len)
      len.zero? and return []
      raise ThreadError if @thread.status=="sleep" and @q.empty?
      result=[]
      begin #loop 
        len.times{ result<<@q.pop(true) }  
        #feh, should fetch more at a time... Queue needs a #read
      rescue ThreadError:
        len-=result.length
      end until @q.empty? and result.length.zero?
    
    ensure
      @pos+=result.length
      return result
    end
    
    def size
      @pos+@q.size
    end
    
    def eof?
      Thread.pass while @q.empty? and @thread.alive?
      @q.empty? and !@thread.alive?
    end

    def each(&block)
      copy=dup
      copy.begin!
      until(copy.eof?)
        block.call copy.read1
      end
    end    
    
    attr :pos

    #methods for Generator compatibility:
    def rewind; begin!; self end
    alias end? eof?
    alias index pos
    def next?; !end? end

    %w[pos= _pos= scan scan_until write [] []= 
       holding holding? holding! position
    ].each{|mname| undef_method mname}
  end
end

end

module Enumerable
  def to_sequence
    Sequence::Enum.new(self)
  end
end
# Copyright (C) 2006,2008  Caleb Clausen
# Distributed under the terms of Ruby's license.
# = sequence.rb - external iterators with capabilities like a text editor cursor
# $Id$
# 
# Author:  Caleb Clausen (sequence-owner @at@ inforadical .dot. net)
# Original Author: Eric Mahurin 
# License: Ruby license
# Home:    http://rubyforge.org/projects/sequence

require "forwardable"
require 'assert'
require 'sequence/version'
require 'sequence/weakrefset'


=begin todo


(.... need to steal more features from Array, String, File, StringScanner, Enumerable?, like:)
  
  
pack/unpack



match/matchback


=end

class Sequence

#  WeakRefSet=::Set
#  warn "warning: sequence uses Set instead of WeakRefSet; memory leak results"

    include Comparable
    include Enumerable
    extend Forwardable

    def initialize; abstract end
    def to_sequence; self end
    
    class<<self
      if nil #borken
      alias original__new new
      undef new #bye-bye
      def new(seq)
        case seq
          when File,IO,Array,String,Enumerable:
            seq.to_sequence
          else
            if seq.respond_to? :to_str
              seq.to_str.to_sequence
            else
              raise ArgumentError
            end          
        end      
      end
      end
      def [](*x) new(*x) end
    end


    public
    # read next element or nil if eof and advance position
    def read1
      (read 1)[0]
    end
    
    # read previous element or nil if start of input and move position back
    def readback1
      (readback 1)[0]
    end
    
    # read element after the pos or nil if eof, leaving position alone
    def readahead1
      slice pos
    end
    
    # read element before the pos or nil if start of input, leaving position alone
    def readbehind1
      slice pos-1 unless pos.zero?
    end
    

    # attempt to read up to +len+ elements. the  position is left just after the data read.
    # #read may return less than the whole requested amount if less data than requested in 
    #+len+ is available. This can happen at end of file or if more data is simply unavailable
    #currently (ie with a Sequence::IO). Don't assume that getting less than you requested 
    #means you're at end of file; use #eof? to test for that instead.
    def read(len)
      abstract
    end
    
    #like read, but position is left alone.
    def readahead(len)
      holding{read(len)}
    end
    
    #read data behind the current  position, leaving position unchanged
    def readbehind(len)
      len>pos and len=pos
      read move( -len)
    end
        
    #read data behind the current  position, leaving position just before the data read.
    def readback(len)
      len>pos and len=pos
      readahead move( -len )
    end

    # read the remaining elements.
    # if reverse, read everything behind position
    def read!(reverse=false)
      if reverse
        readback pos
      else
        read rest_size
      end
    end
    
    def all_data
      holding_position{|posi|
        posi.begin!
        posi.read!
      }
    end




    #a StringScanner-like interface for pattern scanning within sequences.
    #See StringScanner for /(scan|skip|check)(_until)?|match\?|exist\?/.
    #Some notes on the implementation: scanning is all done at the current
    #position. Unlike StringScanner, which only scans for Regexp, this
    #version of #scan, etc allow more pattern types. The pattern type and how 
    #it is treated are determined by whether the underlying data is String-
    #like (contains only characters/bytes), or Array-like (contains any 
    #Object). 
    
    #If String-like: scan and friends can take a Regexp, String, or 
    #Integer (for a single char) parameter.
    #If Array-like: scan and friends can take a scalar matcher (something
    #that responds to ===). Eventually, vector matchers (Reg::Multiple)
    #will be supported as well here. Literal arrays, as patterns to scan for,
    #are not supported: too hard, and there's the quoting problem. 
    #if you actually want to scan for items that are equal to a particular 
    #Regexp (for example), instead of items that match it, use duck.rb
    #to reassign === as ==. Or, if using Reg, create a Reg::Literal by 
    #calling #lit on the pattern (which has the same effect).
  
    #when scanning string-like sequences, anchors in Regexps are treated somewhat 
    #specially:
    #when scanning forward, ^ and \A match at the current position, and
    #$ and \Z match at the end of the sequence. 
    #when scanning backward, ^ and \A match at the beginning of sequence and $ and
    #\Z match at the current position.
    #^ and $ still match at begining and end of lines, as usual.

    #when scanning or matching backwards, ^ has some special problems:
# these won't work....
      #an anchor that might or might not match will break the current implementation in some cases...
      #regexes that should match overall even if the anchor in them doesn't...
#      /(^|)/
      
      #... in strings represents more data which is before the current position
      # position in string is represented by |
#      /(^foo)?bar/==="...xxxfoobar|"
#      /(^[ab]+|b+)/==="...xxxaaabbbbbb|"
#      /(b+|^[ab]+)/==="...xxxaaabbbbbb|"
          
    #scan buffers and maxmatchlen (and ?maxuntillen)
    

#Regexps (or Reg::Multiples in Array-like sequences) are implicitly anchored
#to the current position unless one of the _until forms (or exist?) is used.



=begin can't be abstract... defined in modules
    def scan(pat)
      abstract
    end

    def scan_until(pat)
      abstract
    end
    def scanback(pat)
      abstract
    end

    def scanback_until(pat)
      abstract
    end
    
    def match(pat)
      abstract
    end
    
    def matchback(pat)
      abstract
    end
=end

    def skip(pat)            match=  scan(pat) and match.length    end
    def check(pat)           holding{scan(pat)}    end
    def match?(pat)          holding{skip(pat)}    end
    
    def skip_until(pat)      match=  scan_until(pat) and match.length    end
    def check_until(pat)     holding{scan_until(pat)}    end
    def exist?(pat)          holding{skip_until(pat)}    end

    def skipback(pat)        match=  scanback(pat) and match.length    end
    def checkback(pat)       holding{scanback(pat)}    end
    def matchback?(pat)      holding{skipback(pat)}    end
    
    def skipback_until(pat)  match=  scanback_until(pat) and match.length end
    def checkback_until(pat) holding{scanback_until(pat)} end
    def existback?(pat)      holding{skipback_until(pat) }end
    
    def skip_literal(lits)
      sz=lits.size
      lits==readahead(sz) and move sz
    end
    alias skip_literals skip_literal
  
    def skip_until_literal(lits)
      sz=lits.size
      first=lits[0]
      holding?{
      until eof?
        skip_until(first)
        lits==readahead(sz) and break pos
      end
      }
    end
    alias skip_until_literals skip_until_literal
  
    attr_accessor :last_match
    attr_writer :maxmatchlen
    
    def _default_maxmatchlen; 1024 end
    
    def maxmatchlen(backwards)
      size=self.size
      
      list=[ _default_maxmatchlen,
                       backwards ? pos : size-pos%size
                     ]
                     list.push @maxmatchlen if defined? @maxmatchlen
                     list.min
    end

    #hold current position while executing a block. The block is passed the current
    #sequence as its parameter. you can move the position around or call methods
    #like read that do it, but after the block returns, the position is reset to the
    #original location. The return value is the result of the block.
    def holding
      oldpos=pos
      begin
        yield self
      ensure
        self.pos=oldpos
      end
    end

    #like #holding, but position is reset only if block returns false or nil (or
    #raises an exception).
    def holding?
      oldpos=pos
      begin
        result=yield self
      ensure
        (self.pos=oldpos) unless result
      end
    end

    #like #holding, but block is instance_eval'd in the sequence.
    def holding! &block
      oldpos=pos
      begin
        instance_eval self, &block
      ensure
        self.pos=oldpos
      end
    end


    def holding_position
      pos=position
      begin
        result=yield self
      ensure
        self.position=pos
        pos.close
      end
    end
    
    def holding_position?
      pos=position
      begin
        result=yield self
      ensure
        self.position=pos unless result
        pos.close
      end
    end
    
    def holding_position! &block
      pos=position
      begin
        result=instance_eval self,&block
      ensure
        self.position=pos
        pos.close
      end
    end
        

    # number of elements from the beginning (0 is at the beginning). 
    def pos() 
        abstract
    end
    def rest_size; size - pos end

    #  this checks to see if p is a valid numeric position.
    def pos?(p)
      sz=size
      (-sz..sz)===p
    end

    # Set #pos to be +p+.  When +p+ is negative, it is set from the end.
    def pos=(p)
        position?(p) and p=p.pos unless Integer===p
        self._pos=_normalize_pos p
    end
    
    #go to an absolute position; identical to #pos=
    def goto p
      self.pos= p
    end
    
    def _pos=(p)
      abstract
    end
    # move position +len+ elements, relative to the current position.
    # A negative +len+ will go in reverse.
    # The (positive) amount actually moved is returned (<+len+ if reached beginning/end).
    def move(len)
      oldpos=pos
      newpos=oldpos+len
      newpos<0 and newpos=0
      goto newpos
      return (pos-oldpos).abs
    end
    # move to end of the remaining elements.
    # reverse=true to move to beginning instead of end
    # The amount moved is returned.
    def move!(reverse=false)
      reverse ? begin! : end!
    end

    # Get (if no +value+) and set properties.  Normally, +name+
    # should be a symbol.  If +name+ is +nil+, it wil get/set using a hash
    # representing all of the properties.
    def prop(name=nil,*value) # :args: (name[,value])
        if name.nil?
            if value.size.zero?
                defined?(@prop) &&@prop&&@prop.clone
            else
                if (value = value[0]).nil?
                    defined?(@prop) &&@prop&&remove_instance_variable(:@prop)
                else
                    (@prop||={}).replace(value)
                end
            end
        else
            if value.size.zero?
                defined?(@prop) &&@prop&&@prop[name]
            else
                (@prop||={})[name] = value[0]
            end
        end
    end

    # #position returns a Sequence::Position to represent a location within this sequence.
    # The argument allows you to specify a numeric location for the position; default is
    # currrent position. If the element that a
    # Position is anchored to is deleted, that Position may become invalid
    # or have an unknown behavior.
    def position(_pos=pos)
      Position.new(self,_pos)
    end
    # Set the position to a Position +p+ (from #position).
    def position=(p)
        self.pos = p.pos
        self.prop(nil,p.prop)
        p
    end

    #  this queries whether a particular #position +p+ is valid (is a child or self).
    #  numeric positions and also be tested
    def position?(p)
      case p
      when Integer; (-size..size)===p 
      when Position; equal? p.data
      else equal? p
      end
    end
    
    #make a new sequence out of a subrange of current sequence data.
    #the subseq and parent seq share data, so changes in one 
    #will be reflected in the other.
    def subseq(*args)
      assert !closed?
      first,len,only1=_parse_slice_args(*args)
      SubSeq.new(self,first,len)
    end
    
    #make a new sequence that reverses the order of data.
    #reversed and parent sequence share data.
    def reversed
      Reversed.new self
    end
    
    # Close the sequence.  This will also close/invalidate every child 
# position or derived sequence.
    def close
        defined? @change_listeners and @change_listeners.each { |p| 
          Sequence===p and p.close 
        }
        # this should make just about any operation fail
        instance_variables.each { |v| remove_instance_variable(v) }
        nil
    end
    # Is this sequence closed?
    def closed?
      instance_variables.empty?
    end

=begin who needs it?
    # Compare +other+ (a Position or Integer) to the current position.  return +1
    # for the self is after, -1 for self being before, and 0 for it being at
    # same location, nil (or false) if other is not a position of self.
    def <=>(other)
        if other.respond_to? :to_i then pos<=>other
        elsif position?(other) then pos<=>other.pos
        end
    end
=end

    #if passed an integer arg, return a new position decreased by len. if passed
    # a position, return the distance (number
    # or elements) from +other+ (a #position) to +self+.  This can be +, -, or 0.
    def -(other)
      if position?(other)
        pos-other.pos
      else
        position(pos-other)
      end
    end
    # Returns a new #position increased by +len+ (positive or negative).
    def +(other)
      if ::Sequence===other
        List[self, other]
      else
        position(pos+other)
      end
    end

    # Return a new #position for next location or +nil+ if we are at the end.
    def succ
        self+1 unless eof?
    end
    # Return a new #position for previous location or +nil+ if we are at the beginning.
    def pred
        self-1 unless pos.zero? 
    end
    # Return a new #position for the beginning.
    def begin
      position(0)
    end
    # Return a new #position for the end.
    def end
      position(size)
    end
    
    #go to beginning
    def begin!
      self._pos=0
    end
    #go to end 
    def end!
      self._pos=size
    end

  #-------------------------------------
  #is position within len elements of the beginning?
  def nearbegin(len,at=pos)
    at<=len
  end
  
  #-------------------------------------
  #is position within len elements of the end?
  def nearend(len,at=pos)
    at+len>=size
  end

    #is there any more data after the position?
    def more_data?
      #!eof?
      (size-pos).nonzero?
    end
    
    #has any data been seen so far, or are we still at the beginning?
    def was_data?
      pos.nonzero?
    end
    

    # Returns the number of elements.
    def size
      abstract
    end
    def length; size end

    #are we at past the end of the sequence data, with no more data ever to arrive?
    def eof?
      abstract
    end

    # is there any data in the sequence?
    def empty?
        size==0
    end

    #return first element of data
    def first
        slice 0
    end
    
    #return last element of data
    def last
        slice( -1)
    end

    def _normalize_pos(pos,size=self.size)
          if pos<0 
            pos+=size
            pos<0 and pos=0
          elsif pos>size 
            pos=size    
          end
          
          assert((0..size)===pos)
          pos
    end

    def _parse_slice_args(*args)
      asize=args.size
      assert !closed?
      size=self.size
      case r=args.first
        when Range:
          asize==1 or raise ArgumentError 
          first,last=r.first,r.last
          first=_normalize_pos(first,size)
          last=_normalize_pos(last,size)
          len=last-first 
          r.exclude_end? or len+=1
        when Integer: 
          asize<=2 or raise ArgumentError
          first=_normalize_pos(r,size)
          len=args[1] || (only1=1)
        when nil:
          asize==0 or raise ArgumentError
          first=nil 
          len=only1=1
        else raise ArgumentError
      end
      return first,len,only1
    end

    # Provides random access for the sequence like what is in Array/String.
    # +index+ can be +nil+ (start at the current location) or a numeric 
    # (for #pos=) or a range.
    # +len+ can be +nil+ (get a single element) or the number of elements to
    # #read (positive or negative).  The sequence's position is left alone.
    def slice(*args) #index|range=nil,len=nil
      first,len,only1=_parse_slice_args( *args)
      pos==first and first=nil
      holding {
        self.pos = first if first
        only1 ? read1 : read(len)
      }
    end
    def [](*a) slice(*a) end
    def slice1(idx) slice(idx) end

    # Like #slice except the element(s) are deleted.
    def slice!(*args) #index|range, len 
        first,len,only1=_parse_slice_args( *args)
        result=slice(first,len)
        delete(first,len)
        only1 ? result.first : result
    end
    def slice1!(idx) slice!(idx) end

    # Similar to #slice except data is written.  +index+ and +len+ have the
    # same meaning as they do in #slice.  +len+ elements are deleted and +replacedata+
    # is inserted. +replacedata+ is a single item if len is ommitted and 1st param is Fixnum
    def modify(*args) #index|range, len, replacedata
      abstract
    end
    def []=(*a) modify(*a) end
    
    def delete(*args) #index|range, len
      modify( *args<<new_data)
      nil
    end
    
    def insert index, replacedata
      modify index,0, replacedata
    end
    
    def overwrite index, replacedata
      modify index,replacedata.size, replacedata
    end
    
    def pop count=nil
        slice!(count ? -count...size : -1)
    end
    
    def shift count=nil
        slice!(count ? 0...count : 0 )
    end
    
    def <<(x) push x; return self end
    
    #push/unshift in stringlike/arraylike
    
    def append stuff
      insert(size, stuff)
      self
    end
    
    def prepend stuff
      insert(0, stuff)
      self
    end
  
    def write(data)
      assert oldpos=pos
      writeahead(data)
      assert oldpos==pos
      move data.size
    end
    
    def writeback(data)
      assert oldpos=pos
      writebehind(data)
      assert oldpos==pos
      move( -data.size)
    end
    
    def writeahead(data)
      raise ArgumentError, "attempted overwrite at end of #{self}" if data.size>rest_size
         overwrite(pos,data)
      data.size
    end
    
    def writebehind(data)
      raise ArgumentError, "attempted overwrite at begin of #{self}" if data.size>pos
         overwrite(pos-data.size,data)
      data.size
    end
    
    def _adjust_pos_on_change pos,first,oldsize,newsize
#      assert newsize != oldsize
      if pos>=first+oldsize 
        oldsize.zero? and pos==first and return pos
        pos+newsize-oldsize
      elsif pos>first 
        first
      else pos
      end
    end

    def on_change_notify obj
      Symbol===obj and raise ArgumentError
      obj.respond_to? :change_notification or raise ArgumentError
      @change_listeners||=WeakRefSet[]
      @change_listeners<<obj
    end
    
    def notify_change *args   #seq, first, oldsize, newsize
      args[0]=self
      defined? @change_listeners and @change_listeners.each{|obj|
        obj.change_notification(*args)
      }
    end
    
    # Delete +p+ from the list of children (from #position).
    # Should only be used by child Position.
    def _delete_position(p) # :nodoc:
        @change_listeners.delete(p) 
    end

    # Performs each just to make this class Enumerable.   
    # self is returned (or the break value if the code does a break).
    def each # :yield: value
      holding {
        begin!
        until eof?
          yield read1
        end or self
      } 
    end


end

require 'sequence/position'

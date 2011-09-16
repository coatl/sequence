# $Id$
# Copyright (C) 2006,2008, 2011  Caleb Clausen
# Distributed under the terms of Ruby's license.

require 'sequence'
require 'sequence/arraylike'
require 'sequence/stringlike'
require 'sequence/usedata'
require 'sequence/subseq'

class Sequence
# This class makes a seq over an Array or String.
class Indexed < UseData

class <<self
  alias _orig_new new
  def new(data,p=0)
    if data.respond_to? :to_sequence
      data.to_sequence
    else _orig_new(data,p)
    end
  end
end

    def initialize(data,pos=0)
        @data = data
        @pos = pos
    end
    # :stopdoc:
    def new_data
        @data.class.new
    end

=begin
    protected
    def _delete1after?
        @data.slice!(@pos)
    end
    def _delete1before?
        @pos==0 ? nil : @data.slice!(@pos-=1)
    end
    def _insert1before(v)
        @data[@pos,0] = (new_data << v)
        @pos += 1
        true
    end
    def _insert1after(v)
        @data[@pos,0] = (new_data << v)
        true
    end
public
=end
   
    attr_reader :pos,:data
    def _pos= x; @pos=x end
    
    def eof?; @pos >= size end
    
    def_delegators :@data, :size, :slice, :[]
    
    def maxmatchlen(backwards) size end
    
    #can't change maxmatchlen (maybe someday?)
    def maxmatchlen= x; end
    
    def modify(*args)
      newsize=args.last.size
      first,len,only1=_parse_slice_args( *args[0...-1])
      @data.[]=(*args)
      @pos=_adjust_pos_on_change(@pos, first,len,newsize)
      notify_change(self,first,len,newsize)      
      return args.last
    end
    alias []= modify
    
end

class OfArray < Indexed
  class<<self
    alias new _orig_new
  end
  include ArrayLike
  #scan,scan_until provided by ArrayLike
  
  #a better, string-like #index... with an offset parameter
  #scalar matchers only
  def index(pat,offset=0)
    pat=pat.dup
    class<<pat; alias == ===; end
    offset.zero? and return( @data.index pat)
    @data[offset..-1].index(pat)+offset
  end
    
  #a better, string-like #rindex... with an offset parameter
  #scalar matchers only
  def rindex(pat,offset=size)
    pat=pat.dup
    class<<pat; alias == ===; end
    (offset==size ? @data : @data[0...offset]).rindex pat
  end
    
  def append(arr)
    sz=size
    @data.push(*arr)
    notify_change(self,sz,0,arr.size)
    self
  end

  def new_data
    []
  end

end

class OfString < Indexed
  class<<self
    alias new _orig_new
  end

  include StringLike
  def scan(pat)
    case pat
    when Regexp
      if (m=match pat,true)
        @pos= m.end(0)
        return m.to_s
      end
    when Integer 
      res=@data[@pos]
      if res==pat
        @pos+=1 
        return res.chr
      end
    when String 
      if @data[@pos...@pos+pat.size]==pat
        @pos+=pat.size
        return pat
      end
    end
  end

  def scanback(pat)
    case pat
    when Regexp
      if (m=matchback pat,true)
        @pos= m.begin(0)
        return m.to_s
      end
    when Integer 
      res=@data[@pos]
      if res==pat
        @pos-=1 
        return res.chr
      end
    when String 
      if @data[@pos...@pos-pat.size]==pat
        @pos-=pat.size
        return pat
      end
    end
  end

  def scan_until(pat)
    if Regexp===pat
      if (m=match pat,false) 
        @pos= m.end(0)
        m.pre_match+m.to_s
      end
    else
      i=@data.index(pat,pos) and
        @data[@pos...@pos=i]
    end
  end
  
  def scanback_until(pat)
    if Regexp===pat
      if (m=matchback pat,true)
        @pos= m.begin(0) 
        m.to_s+m.post_match
      end
    else
      i=@data.rindex(pat,pos) or return
      oldpos=@pos
      @data[@pos=i...oldpos]
    end
  end
  
  def match pat,anchored=true,len=size
    len=size
    anchored and pat=_anchor(pat)
    #pat.last_match=
    self.last_match=Thread.current[:last_match]= 
      #can't use String#index here... doesn't do anchors right
      if pat.match @data[pos..-1]
        newpos=@pos+$~.end(0)
        fixup_match_result( $~,[],@pos,:post){
          SubSeq.new(self,newpos,size-newpos)
        } 
      end
  end

  def matchback pat,anchored=true
    anchored and pat=_anchor(pat,:back)
    #pat.last_match=
    self.last_match=Thread.current[:last_match]=
    if pat.match @data[0...pos]
      fixup_match_result($~,[],0,:pre){
        cu=SubSeq.new(self,0,pos=$~.pre_match.size)    
        cu.pos=pos
        cu
      }
    end
  end
    
  def index(pat,offset=0)
    @data.index(pat,offset)
  end

  def rindex(pat,offset=0)
    @data.rindex(pat,offset)
  end

    
  def append(str)
    sz=size
    @data << str
    notify_change(self,sz,0,str.size)
    self
  end

  def new_data
    ""
  end


end

end

class Array
    # convert an array to a seq starting at +pos+
    def to_sequence(pos=0)
       Sequence::OfArray.new(self,pos)
    end
end

class String
    # convert a string to a seq starting at +pos+
    def to_sequence (pos=0)
       Sequence::OfString.new(self,pos)
    end
end



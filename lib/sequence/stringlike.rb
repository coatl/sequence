# Copyright (C) 2006,2008  Caleb Clausen
# Distributed under the terms of Ruby's license.
require 'sequence/subseq'

class Sequence
  module StringLike
    def data_class; String end
    
    def like; StringLike end

    #-------------------------------------
    FFS_4BITTABLE=[nil,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0]
    def ffs
      holding{
        begin!
        zeros=read_til_charset(/[^\0]/)
        byte=read1
        lo=byte&0xF
        rem=FFS_4BITTABLE[lo]||FFS_4BITTABLE[byte>>4]+4
        return zeros.size<<3+rem
      }
    end

    #-------------------------------------
    def fns(bitnum)
      holding{
        goto bitnum>>3
        bitnum&=0x7
        byte=read1
        byte&=~((1<<(bitnum+1))-1)
        if byte.nonzero?
          zeros_size=0
        else
          zeros_size=read_til_charset(/[^\0]/).size
          byte=read1
        end
        lo=byte&0xF
        rem=FFS_4BITTABLE[lo]||FFS_4BITTABLE[byte>>4]+4
        return zeros_size<<3+rem
      }
    end

    #-------------------------------------
    #read until a character in a user-supplied set is found.
    #charrex must be a regexp that contains _only_ a single character class 
    def read_til_charset(charrex,blocksize=16)
       blocks=[]
       m=nil
       until eof?
          block=read blocksize
          #if near eof, less than a full block may have been read
  
          if m=charrex .match(block)
             self.pos-=m.post_match.length+1
             #'self.' shouldn't be needed... but is
  
             blocks<<m.pre_match if m.pre_match.length>0
             break
          end
          blocks<<block
       end
       return blocks.to_s
    end
   

    #-------------------------------------
    #this version is fast and simple, but anchors do not work right,
    #matches are NOT implicitly anchored to the current position, and
    #the file position is not advanced. post_match (or pre_match if
    #going backwards) is always nil.
    def match_fast(rex,backwards=false,len=maxmatchlen(backwards))
      str=send backwards ? :readbehind  : :readahead, len
        if result=rex.match(str)
          if backwards
            def result.pre_match; end
          else
            def result.post_match ; end
          end
        end
      return result
    end
    
    
    
    #-------------------------------------
    #like match, but goes backwards
    def matchback(rex,anchored=true, len=maxmatchlen(true))
      nearbegin=nearbegin(len) 
      newrex,addedgroups=
      if nearbegin && !anchored
       [rex,[]]
      else group_anchors(rex,:back,anchored)
      end
      #do the match against what input we have
      
      matchdata=match_fast(newrex,true,len)
      #fail if any  ^ or \A matched at begin of buffer, 
      #but buffer isn't begin of file
      return if !matchdata or #not actually a match
        addedgroups.find{|i| matchdata.end(i)==0 } && !nearbegin

      matchpos=pos-len
      matchpos>=0 or matchpos=0
      assert(matchpos>=0)
      match1st=position matchpos+matchdata.begin(0)
      result=fixup_match_result(matchdata,addedgroups,matchpos,:pre) do
            result=SubSeq.new(self,0,match1st.pos)
            result.pos=match1st.pos
            result
          end
          #note: pre_match is a subseq.

          #rex.last_match=
          self.last_match=Thread.current[:last_match]=result
    end
    
    #-------------------------------------
    #like match_fast, but anchors work correctly and post_match is
    #set to something, if not exactly what you expected. (an Sequence, not String.)
    #2nd parameter determines if match is anchored on the left side to the 
    #current position or not. 
    def match(rex,anchored=true, len=maxmatchlen(false))
      
      newrex=nearend(len)? rex : group_anchors(rex,false,false).first

      #do the match against what input we have
      matchdata=match_fast(newrex,false,len) or return

      anchored and matchdata.begin(0).nonzero? and return
      posi=position;posi.move matchdata.end(0)
      result=fixup_match_result(matchdata,[],pos,:post) { posi.subseq(posi.pos..-1) }
          #note: post_match is a SubSeq

          #rex.last_match=
          self.last_match=Thread.current[:last_match]=result
    end


  #-------------------------------------
  #if not backwards:
  #replace \Z with (?!) 
  #replace $ with (?=\n) 
  #if backwards:
  #replace \A with (?!) 
  #replace ^ with (^) (and adjust addedgroups)
  #there's no lookback in ruby regexp (yet)
  #so, ^ in reverse regexp will perhaps lead to unexpected
  #results. some matches with ^ in them will fail, when they
  #should have succeeded even if the ^ couldn't match.
  #you should be pretty much ok if you
  #don't use ^ within alternation (|) in backwards match.
  #if anchored, an implicit anchor is added at the end (begin if backwards)
  #there's also a nice cache,so that the cost of regexp rebuilding is reduced
  #returns: the modified regex and addedgroups
  def group_anchors(rex,backwards,anchored=false)
    @@fs_cache||={}
    result=@@fs_cache[[rex,backwards,anchored]] and return result
    if backwards 
      caret,dollar,buffanchor='^',nil,'A'
    else 
      caret,dollar,buffanchor=nil,'$','Z' 
    end
    newrex=(anchored ?  _anchor(rex,backwards,false) : rex.to_s)

    rewritten=incclass=false
    groupnum=0
    addedgroups=[]
    result=''
    (frags=newrex.split( /((?:[^\\(\[\]$^]+|\\(?:[CM]-)*[^CMZA])*)/ )).each_index{|i|
      frag=frags[i]
      case frag
        when "\\": 
          if !incclass and frags[i+1][0,1]==buffanchor
            frags[i+1].slice! 0
            frag='(?!)'
            rewritten=true
          end
        when caret 
          unless incclass
            addedgroups<<(groupnum+=1)
            frag="(^)"
            rewritten=true
          end
        when dollar 
          unless incclass
            frag="(?=\n)"
            rewritten=true
          end
        when "(": incclass or frags[i+1][0]==?? or groupnum+=1
        when "[": incclass=true #ignore stuff til ]
        when "]": incclass=false #stop ignoring stuff
      end
      result<<frag
    }
    
    newrex=rewritten ? Regexp.new(result) : rex
    
    @@fs_cache[[rex,backwards,anchored]]=[newrex,addedgroups]
  end
   

  #-------------------------------------
  @@anchor_cache={}
  #add an anchor to a Regexp-string. normally, 
  def _anchor(str,backwards=false,cache=true)
    cache and result=@@anchor_cache[[str,backwards]] and return result
    result=backwards ? "(?:#{str})\\Z" : "\\A(?:#{str})"
    cache and return @@anchor_cache[[str,backwards]]||=Regexp.new( result )
    return result
  end
 
  #-------------------------------------
  def fixup_match_result(matchdata,addedgroups,pos_adjust,namelet,&body)

    #remove extra capture results from () we inserted from MatchData
    #..first extract groups, begin and end idxs from old
    groups=matchdata.to_a
    begins=[]
    ends=[]
    matchdata.to_a.each_with_index{|substr,i| 
      next unless substr
      begins<<matchdata.begin(i)+pos_adjust
      ends<<matchdata.end(i)+pos_adjust
    }
    
    #..remove data at group indexes we added above
    addedgroups.reverse_each{|groupidx| 
      [groups,begins,ends].each{|arr| arr.delete_at groupidx }
    }
    
    #..now change matchdata to use fixed-up arrays
    result=CorrectedMatchData.new
    result.begins=begins
    result.ends=ends
    result.groups=groups
    if namelet==:pre
      result.set_pre_match_body( &body)
      result.set_post_match_body {matchdata.post_match}
    else
      result.set_pre_match_body {matchdata.pre_match}
      result.set_post_match_body( &body)
    end
    result.pos=pos_adjust
    
    result
  end    
  
  

  #-------------------------------------
  class CorrectedMatchData < MatchData
    class<<self
      alias new allocate
    end
  
    def initialize; end
  
    attr_reader :pos
    attr_writer :begins,:ends,:groups,:pos
    
    def set_pre_match_body &body
      @pre_match_body=body
    end
    
    def set_post_match_body &body
      @post_match_body=body
    end
    
    def pre_match
      @pre_match_body[]
    end
    
    def post_match
      @post_match_body[]
    end
    
    def [](*args); @groups[*args] end
  
    def begin n;  @begins[n]  end
    def end n;    @ends[n] end
    def offset n; [@begins[n],@ends[n]] if n<size end
  
    def to_a;     @groups end
    def to_s;     @groups.first end
    def size;     @groups.size end
    alias length size
    
    
    
  end
  


    def scan(pat)
      holding? {case pat
        when Integer: 
          pat==read1 and pat.chr
        #when SetOfChar: ...
        when String:
          pat==read(pat.size) and pat
        when Regexp: 
          if m=match(pat,true)
            goto m.end(0) 
            m.to_s
          end
        else raise ArgumentError.new("bad scan pattern for Sequence::StringLike")
      end}
    end
    
    def scanback(pat)
      holding? {case pat
        when Integer: 
          pat==readback1 and pat.chr
        #when SetOfChar: ...
        when String:
          pat==readback(pat.size) and pat
        when Regexp: 
          if m=matchback(pat,true) 
            goto m.begin(0) 
            m.to_s
          end
        else raise ArgumentError.new("bad scan pattern for Sequence::StringLike")
      end}
    end
    
    def scan_until(pat)
      at=index( pat,pos) or return
      newpos=case pat
        when Regexp: 
          m=last_match
          s=slice(pos...m.begin(0))
          m.set_pre_match_body{s}
          m.end(0)
        when String: at+pat.size
        when Integer: at+1
        #when SetOfChar: huh
        else raise ArgumentError
      end
      return( read newpos-pos)

=begin    
      holding? {
        if Regexp===pat
          until_buffer_len=4*maxmatchlen(false)
          until_step_len=3*maxmatchlen(false)
          holding_position{|posi|
            until posi.eof?
              if m=posi.match(pat,false,until_buffer_len)
                pre=read(posi.pos-pos)+m.pre_match
                m.set_prematch_body {pre} #readjust matchdata to include data between my own pos and posi
                goto m.end(0)  #advance my own position to end of match
                return m.pre_match+m.to_s #return match and what preceded it
              end
              posi.move until_step_len
            end
            nil
          }
        #elsif SetOfChar===pat: ...
        else #string or integer
          i=index(pat,pos)
          result=read(i-pos)<<pat
          move(pat.is_a?( Integer ) ? 1 : pat.size)
          result
        end
      }
=end
    end
    
    def scanback_until(pat)
      at=rindex( pat,pos) or return
      newpos=
        if Regexp===pat
          m=last_match
          s=slice(m.end(0)+1..pos)
          m.set_post_match_body{s}
          m.begin(0)
        else at
        end
      assert(newpos<=pos)
      return( readback pos-newpos)

=begin
      holding? {
        if Regexp===pat
          huh #need to scan til eof, like #scan_until does
          m=matchback(pat,false) or break
          goto= m.begin(0)
          m.to_s+m.post_match
        #elsif SetOfChar===pat: ...
        else #string or integer
          i=rindex(pat,pos)
          result=readback(pos-i-pat.size)<<pat
          move( -(pat.is_a? Integer ? 1 : pat.size))
          result
        end
      }
=end
    end
    
    def push(str)
      Integer===str and str=str.chr
      insert size, str
    end
    
    def unshift(str)
      Integer===str and str=str.chr
      insert 0, str
    end
    
    def index pat,pos=0
      posi= self.begin()
      until_buffer_len=4*maxmatchlen(false)
      if Regexp===pat
        until_step_len=3*maxmatchlen(false)
          until posi.eof?
            if m=posi.match(pat,false,until_buffer_len)
              range=0...m.begin(0)
              pre=subseq(range)
              m.set_pre_match_body { pre } 
              self.last_match=m
              return m.begin(0) #return match and what preceded it
            end
            posi.move until_step_len
          end
      #elsif SetOfChar===pat; ...
      else
        until_step_len=until_buffer_len
        String===pat and until_step_len-=pat.size-1          
          until posi.eof?
            buf=posi.readahead(until_buffer_len)
            if i=buf.index( pat)
              result=posi.pos+i
              return result
            end
            posi.move until_step_len
          end
      end
      return nil
    ensure
      posi.close
    end
    
    def rindex pat,pos=size-1
      posi= self.end()
      until_buffer_len=4*maxmatchlen(false)
      if Regexp===pat
        until_step_len=3*maxmatchlen(false)
          until posi.pos.zero?
            if m=posi.matchback(pat,false,until_buffer_len)
              range=m.end(0)+1..-1
              post=subseq(range)
              m.set_post_match_body { post } 
              self.last_match=m
              posi.close
              return m.begin(0) #return match and what preceded it
            end
            posi.move( -until_step_len )
          end
      #elsif SetOfChar===pat; ...
      else
        until_step_len=until_buffer_len
        String===pat and until_step_len-=pat.size-1          
          until posi.pos.zero?
            buf=posi.readbehind(until_buffer_len)
            if i=buf.rindex( pat)
              result=posi.pos-until_buffer_len+i
              posi.close
              return result
            end
            posi.move( -until_step_len )
          end
      end
      return nil
    ensure
      posi.close
    end
    
    
    
    
    #be nice to have #pack and #unpack too
  end
end

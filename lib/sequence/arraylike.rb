# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.
class Sequence
  module ArrayLike
    def data_class; Array end
    def like; ArrayLike end

    def scan(pat)
        elem=nil
        more_data? and holding?{pat===(elem=read1)} and return [elem]
    end
    
    def scan_until pat
        i=index(pat,pos) or return
        read(i-pos)+scan(pat)
    end
    
    def scanback pat
        elem=nil
        was_data? and holding?{pat===(elem=readback1)} and return [elem]
    end

    def scanback_until pat
        i=rindex(pat,pos) or return
        readback(pos-i)
    end

    #I ought to have #match and #matchback like in StringLike too
    
    def push(*arr)
      append arr
    end
    
    def unshift(*arr)
      prepend arr
    end
    
    def index pat,pos=0
      pos=_normalize_pos(pos)
      begin
        pat===(slice pos) and return pos
        pos+=1
      end until pos>=size
      nil
    end
    
    def rindex pat,pos=-1
      pos=_normalize_pos(pos)
      begin
        pat===(slice pos) and return pos
        pos-=1
      end until pos<0
      nil
    end
    
  end
end

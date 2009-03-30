# $Id$
# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.

require 'sequence'
require 'sequence/usedata'

class Sequence
# Objects in this class are mainly used to simply mark/remember the location
# of a parent sequence.  But, this class also has the fully functionality of the
# parent.  When this child wants to do an operation, it uses the parent to
# do it and returns the parent to where it was.
class Position < UseData # :nodoc:
    def initialize(parent,pos=parent.pos)
        Position===parent and raise ArgumentError
        @data = parent
        @pos = _normalize_pos pos
        extend parent.like
        prop(nil,parent.prop)
        @data.on_change_notify self
    end
    
    def change_notification data,first,oldsize,newsize
      assert @data==data 
      @pos=_adjust_pos_on_change @pos,first,oldsize,newsize
      
      notify_change self,first,oldsize,newsize 
    end
    
    
    


    def _pos=(p)
            @pos = p
    end
    def position(pos=@pos)
      @data.position(pos)
    end

#    undef_method(:_delete_position)

    def_delegators :@data, :size, :data_class, :[], :[]=, :slice
    def_delegators :@data, :new_data, :all_data, :pos?, :position?
    def_delegators :@data, :begin, :end, :empty?, :index, :rindex, :slice!
    def_delegators :@data, :modify, :append, :prepend, :overwrite
    def_delegators :@data, :insert, :delete, :push, :pop, :shift, :unshift
    
    alias dup position

   def nearbegin(len,at=pos)
     @data.nearbegin(len,at)
   end

   def nearend(len,at=pos)
     @data.nearend(len,at)
   end

    
    
    def eof?; @pos>=size end

    attr_reader :data,:pos

     
    def closed?
      super or @data.closed?
    end
    
   def close
        @data._delete_position(self)
        super
    end
=begin ***
    protected
    def _deletion(pos,len=1,reverse=false,dummy=nil)
        if @pos==pos
            @anchor_after = false
        elsif @pos>pos
            @pos -= len
            if @pos<pos
                @pos = pos
                @anchor_after = !reverse
            elsif @pos==pos
                @anchor_after = true
            end
        end
        nil
    end
    def _insertion(pos,len=1,dummmy=nil)
        if @pos>=pos+(@anchor_after ? 0 : 1)
            @pos += len
        end
        nil
    end
=end
end
end



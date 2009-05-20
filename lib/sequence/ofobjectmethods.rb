# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.
require 'sequence'
require 'sequence/indexed'
require 'sequence/functional'
require 'set'


class Sequence
  class OfObjectMethods < OfArray
    def initialize obj, exceptions=[], extras=[] #,modifiable=false
      @obj=obj
      methods=obj.public_methods.-(Functional.nonfunctions_of(obj)).-(exceptions)
      methods.reject!{|name| /[!=]$/==name }
      @data.concat extras.map{|x| Symbol===x ? x.to_s : x }
      @data=methods.inject([]){|l,name| l+[name,nil]}
      #@data.freeze unless modifiable      
      
      @is_exception=0
      @is_reified=0
    end
    
    def is_exception?(index) @is_exception&(1<<index/2) == 0 end    
    def set_exception!(index) @is_exception|= 1<<index/2 end
    
    def is_reified?(index) @is_reified&(1<<index/2) == 0 end    
    def set_reified!(index) @is_reified|= 1<<index/2 end
 
    def modify(*args)
      repldata=args.pop
      start,len,only1=_parse_slice_args(*args)
      len==1 or raise ArgumentError,"scalar modifications to objects only!"
      start.%(2).nonzero? or raise ArgumentError, "OfObjectMethods#modify will not change method names!"
      
      if Array===@data[start-1]
        if @data[start-1].first.to_s=='[]'
          @obj.send(:[]=, @data[1..-1],repldata)
        else raise ArgumentError, "trying to call settor with extra args"
        end
      else        
      
        @obj.send(@data[start-1]+"=",repldata.first)
        @data[start]=repldata.first
      end
      repldata
    end
 
    def reify_from_index(i)
        #if the call raises an exception, store the exception instead of the result 
        #and remember (in @is_exception) that this particular result is an exception
        if is_reified? i
          raise @data[i+1] if is_exception? i
          return 
        end
        set_reified! i
          begin 
            @data[i+1]=
              if Array===@data[i]
                @obj.send(*@data[i])
              else
                @obj.send(@data[i]) 
              end
          rescue Exception=>exc
            set_exception!(i)
            @data[i+1]=exc
            raise
          end    
    end
    
    def reify(itemref)
    
      if itemref.is_a? String or itemref.is_a? Symbol
        i=0
        begin 
          i=@data.index(itemref.to_s,i)  
          i or @data.push itemref.to_s, nil
        end while i and i%2!=0
        reify_from_index(i)
      elsif itemref.is_a? Integer and itemref>=0 and itemref%2==0
        reify_from_index(itemref)
      else
        raise ArgumentError
      end
      return nil
    end
  end
end

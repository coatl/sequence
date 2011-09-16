# Copyright (C) 2006, 2011  Caleb Clausen
# Distributed under the terms of Ruby's license.
require 'sequence'
require 'sequence/indexed'


class Sequence
  class OfObjectIvars < OfArray
    def initialize(obj,exceptions=[],modifiable=false)
      @obj=obj
      ivars=obj.instance_variables - exceptions
      @data=ivars.inject([]){|l,name| l.push name,obj.instance_variable_get(name)}
      @data.freeze unless modifiable
    end
    
    def modify(*args)
      repldata=args.pop
      start,len,only1=_parse_slice_args(*args)
      len==1 or raise "scalar modifications to objects only!"
      assert start.%(2).nonzero? #not a name 
      
      @obj.instance_variable_set(@data[start-1],repldata.first)
      @data[start]=repldata.first 
      repldata
      
    end
    
  end
end
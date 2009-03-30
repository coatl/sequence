# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.
  
class Sequence
  #i thought ruby had this already, but i can't find it...
  class WeakHash
    #dunno if this is thread-safe
    def initialize hash={},default=nil,&block
      @hash=block ? Hash.new(&block) : Hash.new(default)
      hash.each{|(k,v)|
        self[k]=v    
      }
    end
    
    def delete_when_dies key
      ObjectSpace.define_finalizer(key){|id| @hash.include? id and @hash.delete id}  
      return key
    end
    
    def [] key
      @hash[key.__id__]
    end
    
    def []= key, val
      delete_when_dies key
      @hash[key.__id__]=val
    end
    
    def delete key
      @hash.delete key.__id__
    end
    
    def values
      @hash.values
    end
    
    def keys
      @hash.keys.map!{|id| ObjectSpace._id2ref(id)}
    end
  end

  #methods (and constants) related to functional programming
  module Functional;  end
  class<<Functional  
    HAS_SIDE_EFFECT=WeakHash.new
    NO_SIDE_EFFECT=WeakHash.new
    #hashes of Module (or Class, including meta-Class) to a list of method names
    #which do or don't have side effects
    def functions_of(obj)
      published=Set[public_methods_of(obj).delete_if{|name| /[!=]$/===name}]
      result=[]
      list=class<<obj; ancestors.unshift self end
      list.each{|mod| 
        result.push( *published&NO_SIDE_EFFECT[mod] )
        published&=Set[*NO_SIDE_EFFECT[mod]+HAS_SIDE_EFFECT[mod]]
      }
      return result
    end
    
    def maybe_functions_of(obj)
      published=public_methods_of(obj).delete_if{|name| /[!=]$/===name}
      result=[]
      list=class<<obj; ancestors.unshift self end
      list.each{|mod| 
        published.delete_if{|name| 
          NO_SIDE_EFFECT[mod].include? name || 
          HAS_SIDE_EFFECT[mod].include? name
        }
      }
      return result
    end
   
    def nonfunctions_of(obj)
      public_methods_of(obj)-functions_of(obj)-maybe_functions_of(obj)
    end
    
    def is_function?(obj,name)
      list=class<<obj; ancestors.unshift self end
      list.each{|mod| 
        return true if NO_SIDE_EFFECT[mod].include? name
        return false if HAS_SIDE_EFFECT[mod].include? name
      }
      return false
    end
    
    def is_maybe_not_function?(obj,name)
      !is_function(obj,name)
    end
    
    def is_maybe_function?(obj,name)
      list=class<<obj; ancestors.unshift self end
      list.each{|mod| 
        return true if NO_SIDE_EFFECT[mod].include? name
        return false if HAS_SIDE_EFFECT[mod].include? name
      } 
      return true
    end
    
    def is_not_function?(obj,name)
      !is_maybe_function(obj,name)
    end

    PMETHS_REF= ::Object.instance_method("public_methods")
    def public_methods_of(obj)
      PMETHS_REF.bind(obj).call
    end
  end

end

class Module
  def has_side_effect(*names)
    names.map!{|name| name.to_s}
    Functional::HAS_SIDE_EFFECT[self]|= names
    Functional::NO_SIDE_EFFECT[self] -= names
  end
  
  def no_side_effect(*names)
    names.map!{|name| name.to_s}
    Functional::NO_SIDE_EFFECT[self] |= names
    Functional::HAS_SIDE_EFFECT[self]-=names
  end
end

class Object
  has_side_effect *l=%w(__send__ display extend freeze instance_eval instance_exec instance_variable_set method_missing send taint untaint)
  no_side_effect *instance_methods(false)-l
end
class String
  has_side_effect  *l=%w(<< []= capitalize! chomp! chop! concat delete! downcase! gsub! lstrip! next! replace reverse! rstrip! slice! squeeze! strip! sub! succ! swapcase! tr! tr_s! upcase!)
  no_side_effect  *instance_methods(false)-l
end
class Array
  has_side_effect  *l=%w(<< []= clear collect! compact! concat delete delete_at delete_if fill flatten! insert map! pop push reject! replace reverse! shift slice! sort! uniq! unshift)
  no_side_effect  *instance_methods(false)-l
end
class Hash
  has_side_effect  *l=%w([]= clear default= delete delete_if merge! rehash reject! replace shift store update)
  no_side_effect  *instance_methods(false)-l
end
class Class
  has_side_effect *%w(inheirited new)
  no_side_effect *%w(allocate superclass)
end
class Module
  has_side_effect  *l=%w(class_eval const_set module_eval private_class_method public_class_method)+private_instance_methods(false)-["class_variable_get"]
  no_side_effect  *["class_variable_get"]+instance_methods(false)-l
end
class Proc
  has_side_effect *%w[[] call]
  no_side_effect "arity"
end
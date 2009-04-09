# $Id$
# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.

require 'yaml'
require 'assert'

# WeakRefSet implements an unordered collection of weak references to objects.
# These references don't prevent garbage collection on these objects.  As these
# objects are thrown away so does their entry in a WeakRefSet.  Immmediate
# objects are not handled by this class (and wouldn't be useful).
class WeakRefSet
    include Enumerable
    # create a new WeakRefSet from an optional Enumerable (of objects)
    # which is optionally processed through a block
    def initialize(items) # :yield: obj
        replace(items)
    end
    class<<self
      def [] *items
        new(items)
      end
    end

    private
    def finalizer(id)
        @ids.delete(id)
    end

    public



    # add a weak reference to the set
    def add(obj)
        Symbol===obj || Fixnum===obj || nil==obj || true==obj || false==obj and 
          raise ArgumentError, "no immediates in weakrefset"
        id=obj.object_id
        case (o2=ObjectSpace._id2ref id) #test id for validity
        when Symbol,Fixnum,true,false,nil:          id=obj #hopefully rare
        else         obj.equal? o2 or raise
          ObjectSpace.define_finalizer(obj,method(:finalizer))
        end
        @ids[id] = true
        self
    end
    alias << add
    # iterate over remaining valid objects in the set
    def each
        @ids.each_key { |id|
          case id
          when Integer:
            begin
                o = ObjectSpace._id2ref(id)
            rescue RangeError
                next
            end
            @ids.include?(id) or next
            #i don't know where the random symbols come from, but at least they're always symbols...
          else
            o=id
          end
            case o
              when Symbol,Fixnum,true,false,nil: warn "immediate value #{o.inspect} found in weakrefset"
              else yield(o) 
            end
        }
        self
    end
    
    def == other
      size==other.size and
      each{|x|
        other.include? x or return
      }
    
    end
    
    # clear the set (return self)
    def clear
        @ids = {}
        self
    end
    # merge some more objects into the set (return self)
    def merge(enum)
        enum.each { |obj| add(obj) }
        self
    end
    # replace the objects in the set (return self)
    def replace(enum)
        clear
        merge(enum)
        self
    end
    # delete an object in the set (return self)
    def delete(obj)
        delete?(obj)
        self
    end
    # delete an object in the set (return self or nil if nothing deleted)
    def delete?(obj)
        x=include?(obj) and @ids.delete(x.__id__)||@ids.delete(x) and self
    end
    # is this object in the set?
    def include?(obj)
        find{|x| obj==x}
    end
    alias member? include?

    # return a human-readable string showing the set
  def inspect
    #unless $weakrefset_verbose_inspect 
    #  return sprintf('#<%s:0x%x {...}>', self.class.name, object_id)
    #end
    ids = (Thread.current[:__weakrefset__inspect_key__] ||= [])

    if ids.include?(object_id)
      return sprintf('#<%s {...}>', self.class.name)
    end

    begin
      ids << object_id
      return sprintf('#<%s {%s}>', self.class.name, to_a.inspect[1..-2])
    ensure
      ids.pop
      Thread.current[:__weakrefset__inspect_key__].empty? and
        Thread.current[:__weakrefset__inspect_key__]=nil
    end
  end

if false      #this is broken; emits yaml for a hash. 

  YAML::add_domain_type( "inforadical.net,2005", "object:WeakRefSet" ) do |type, val|
       WeakRefSet.new( *val["items"] )
  end

  def is_complex_yaml?; true  end
  
  def to_yaml_type; "!inforadical.net,2005/object:WeakRefSet" end
  
  alias to_yaml_properties to_a
  
  def to_yaml( opts = {} )
    YAML::quick_emit( object_id, opts ) { |out|
      out.map( to_yaml_type ) { |map|
        map.add( "items", to_yaml_properties)
      }
    }
  end
end
  
    # remove some objects from the set (return self)
    def subtract(enum)
        enum.each { |obj| delete(obj) }
        self
    end
    # any objects in the set still valid?
    def empty?
        @ids.empty?
    end
    # number of objects in the set still valid
    def size
        @ids.size
    end
    alias length size
end

# :stopdoc:

if __FILE__==$0
    require 'benchmark'
    class MyString <String;
      def initialize(*)
        @owner=0
        super
      end
     
    end
    class MyObject; end
    class MyClass < Module; end
    weakrefsets = (1..10).map {WeakRefSet[]}
    $stdout.sync=true
    obj = nil
    arr=[]
#    srand(2389547343)
    classes=[]
    ObjectSpace.each_object(Class){|ob| classes<<ob}
    classes-=[Symbol,Integer,NilClass,FalseClass,TrueClass,Numeric,Data,Bignum,Fixnum,
              Float,Struct,Method,UnboundMethod,Proc,Thread,Binding,Continuation]
    classes.delete_if{|k| begin k.allocate; rescue; true else false end}
    def shuffle!(arr)
      arr.sort_by{rand}    
    end
    times = Benchmark.measure {
    100000.times { |i|
#        print(weakrefs.size>70?"|":((60..70)===weakrefs.size ? ":" : (weakrefs.size>50?',':'.')))
        print "." if 0==i%128
        #obj = (k=classes[rand(classes.size)]).allocate  
        obj = (k=MyString).new "X" #*rand(i+1)
#        obj= (k=Object).new
#        obj= (k=MyObject).new
        #obj= (k=MyClass).new
        k==obj.class or raise
        weakrefs=weakrefsets[rand(weakrefsets.size)]
        obj.instance_eval{@owner=weakrefs}
        obj.instance_eval{@owner}.equal? weakrefs or raise
        weakrefs.each { |o|
 #           k==o.class or raise "set contained a #{o.class}. i=#{i}. size=#{weakrefs.size}"
            (o2=o.instance_eval{@owner})==weakrefs or 
               raise "expected owner #{weakrefs.map{|w| w.__id__}.inspect}, "+
              "got #{o2.inspect}, item #{o}, id #{o.__id__}, obj #{obj.__id__}"
        }
        weakrefs << obj
        weakrefs.each { |o|
 #           k==o.class or raise "set contained a #{o.class}. i=#{i}. size=#{weakrefs.size}"
            (o2=o.instance_eval{@owner})==weakrefs or 
               raise "expected owner #{weakrefs.map{|w| w.__id__}.inspect}, "+
              "got #{o2.inspect}, item #{o}, id #{o.__id__}, obj #{obj.__id__}"
        }
        weakrefs.include?(obj) or raise
        weakrefs.each { |o|
 #           k==o.class or raise "set contained a #{o.class}. i=#{i}. size=#{weakrefs.size}"
            (o2=o.instance_eval{@owner})==weakrefs or 
               raise "expected owner #{weakrefs.map{|w| w.__id__}.inspect}, "+
              "got #{o2.inspect}, item #{o}, id #{o.__id__}, obj #{obj.__id__}"
        }
        weakrefs.include?(obj) or raise
        if rand(10).zero?
            weakrefs.delete?(obj) or raise
            !weakrefs.include?(obj) or raise
        elsif rand(4).zero?
          arr<<obj #prevent garbage collection
        end
        if rand(1000).zero?
          shuffle! arr
          arr.slice!(0..rand(arr.size))
        end
        arr.each{|o| o.instance_eval{@owner}.include? o or raise }
        #rand(100).zero? and          GC.start
    }
    }
    puts
    GC.start
    weakrefsets.each{|weakrefs|
    weakrefs.clear
    weakrefs.size.zero? or raise
    weakrefs.empty? or raise
    }
    puts(times)
end

# :stopdoc:



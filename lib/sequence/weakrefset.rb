# $Id$
# Copyright (C) 2006,2008  Caleb Clausen
# Distributed under the terms of Ruby's license.

#require 'yaml'
require 'set'
begin
  require 'weakref'
rescue Exception
end

# WeakRefSet implements an unordered collection of weak references to objects.
# These references don't prevent garbage collection on these objects.  As these
# objects are thrown away so does their entry in a WeakRefSet.  Immmediate
# objects are not handled by this class (and wouldn't be useful).
class WeakRefSet<Set
  include Enumerable
  # create a new WeakRefSet from an optional Enumerable (of objects)
  # which is optionally processed through a block
  def initialize(items=nil,&block) # :yield: obj
    items=[] if items.nil?
    raise ArgumentError unless items.respond_to? :each
    items=items.map(&block) if block
    replace(items)
  end
  alias initialize_copy initialize
  class<<self
    def [] *items
      new(items)
    end
  end

  private
  def finalizer(id)
    @ids.delete(id)
  end

sss="a string"
if WeakRef.respond_to? :create_weakref   and  #rubinius
   WeakRef.create_weakref(sss).at(0).equal?(sss)

  def ref o
    WeakRef.create_weakref o
  end
  def unref id
    id.at(0)
  rescue Exception
    return nil
  end

else

  def ref o
    o.__id__
  end
  def unref id
    ObjectSpace._id2ref id
  rescue RangeError
    return nil
  end
end

  public

  # add a weak reference to the set
  def add(obj)
    return self if include? obj
#        Symbol===obj || Fixnum===obj || nil==obj || true==obj || false==obj and 
#          raise ArgumentError, "no immediates in weakrefset"
        id=ref obj
        case (o2=unref id) #test id for validity
        when Fixnum; 
          obj.equal? o2 or raise
        when Symbol,true,false,nil;          id=obj #hopefully rare
        else         
          obj.equal? o2 or raise
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
          when Integer
            @ids.include?(id) or next
            o = unref(id) or next
            #i don't know where the random symbols come from, but at least they're always symbols...
          else
            o=id
          end
#          case o
#            when Symbol,Fixnum,true,false,nil: warn "immediate value #{o.inspect} found in weakrefset"
#            else 
              yield(o) 
#          end
        }
        self
  end

  def to_a
    map{|x| x}
  end

  def == other
    return true if self.equal? other
    other.is_a? Set and other.size==self.size and
      all?{|x| other.include?(x) }
  end
  alias eql? ==

  def hash
    result=0
    each{|x| result^=x.hash }
    result
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

  # delete an object in the set (return self if obj was found, else nil if nothing deleted)
  def delete?(obj)
    x=include?(obj)
    if x
      fail unless  @ids.delete(ref( x ))||@ids.delete(x)
      return self
    end
  end

  # Deletes every element of the set for which block evaluates to
  # true, and returns self.
  def delete_if
    to_a.each { |o| delete(o) if yield(o) }
    self
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

  # Returns a new set containing elements exclusive between the set
  # and the given enumerable object.  (set ^ enum) is equivalent to
  # ((set | enum) - (set & enum)).
  def ^(enum)
    enum.is_a?(Enumerable) or raise ArgumentError, "value must be enumerable"
    n = self.class.new(enum)
    each { |o| if n.include?(o) then n.delete(o) else n.add(o) end }
    n
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
    maybe_Data=Data if defined? Data #whatever Data is supposed to be, idunno.....
    classes-=[Symbol,Integer,NilClass,FalseClass,TrueClass,Numeric,maybe_Data,Bignum,Fixnum,
              Float,Struct,Method,UnboundMethod,Proc,Thread,Binding,Continuation]
    classes.delete_if{|k| begin k.allocate; rescue; true else false end}
    def shuffle!(arr)
      arr.sort_by{rand}    
    end

    iterations=ARGV[0]||100_000
    iterations=iterations.to_i

    times = Benchmark.measure {
    iterations.times { |i|
#        print(weakrefs.size>70?"|":((60..70)===weakrefs.size ? ":" : (weakrefs.size>50?',':'.')))
        print "." if 0==i%128
        #obj = (k=classes[rand(classes.size)]).allocate  
        obj = (k=MyString).new "X#{rand(i+1)}_#{i}"
#        obj= (k=Object).new
#        obj= (k=MyObject).new
        #obj= (k=MyClass).new
        k==obj.class or raise
        weakrefs=weakrefsets[rand(weakrefsets.size)]
        obj.instance_eval{@owner=weakrefs}
        obj.instance_eval{@owner}.equal? weakrefs or raise
        weakrefs << obj
        weakrefs.include?(obj) or raise
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




   class NotReallyWeakRefSet<WeakRefSet
     #ensure the items referenced never get gc'd
     class<<self
       @@keeprefs=[]
       def new(*args)
         @@keeprefs.concat args
         super
       end
     end
   end

   #"now I should reuse Set's original tests, but replacing Set with NotReallyWeakRefSet"
   origset=$:.find{|dir| File.exist? dir+"/set.rb"} +"/set.rb"
   testcode=File.read(origset).split("\n__END__\n",2).last
   testcode=testcode.split("\nclass TC_SortedSet",2).first #hack off some unwanted tests
   testcode.gsub! 'Set', 'NotReallyWeakRefSet'

   eval testcode
end

# :stopdoc:



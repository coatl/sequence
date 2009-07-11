# Copyright (C) 2006,2008  Caleb Clausen
# Distributed under the terms of Ruby's license.
$VERBOSE=1
require 'test/unit'


      require 'sequence'
      require 'sequence/indexed'
      require 'sequence/reversed'
      require 'sequence/position'
      require 'sequence/circular'
      require 'sequence/buffered'
      require 'sequence/shifting'
      require 'sequence/file'
      require 'sequence/list'
      require 'sequence/io'
      require 'tempfile'
      
     
BEGIN {
  if seedstr=ENV['SEED']
    seed=seedstr.to_i
    srand seed
  else
    rand;
    seed=srand  
  end
  
  puts "random seed is #{seed}"
}

$Debug=true

  class SequenceTests 
  
      DATA="foo\nbar baz that tough guy talk\ndon't make you a dog"
      DATA.freeze
    OFFSET=12
    
    
    class Indexed  <Test::Unit::TestCase
      def a_seq
        #assert_equal 52==DATA.size
        seq= Sequence::Indexed.new(DATA.dup)
        seq.move(OFFSET)
        return seq
      end
      def absolutes_always_fail; false end
      
      #forward decls
      def nop; end
      MOVEPOSMETHODS=%w[test_nearbegin test_nearend
        test_pos 
        test_pos= 
       test_scanning 
        test_readahead 
        test_read 
        test_slice 
        test_slice_empty 
        test_optional_capture
      ]
      MODIFYMETHODS=%w[
        test_insert 
        test_delete 
        test_modify 
        test_insert_empty 
        test_delete_empty 
        test_insert_start 
        test_delete_start 
        test_insert_end 
        test_delete_end 
        test_randomized_methods_some_more  
        test_write 
        test_writeback 
                test_write_and_read_joints 
        test_insert_and_read_joints 
        test_delete_and_read_joint 
        test_modify_and_read_joints 
        test_pos_munging 
      ]
      (MOVEPOSMETHODS+MODIFYMETHODS).each{|m| alias_method m, :nop }
      
      

    end
    
    class Position <Indexed
      def a_seq
        super.position
      end
    end
    class SubSeq1 <Indexed
      def a_seq
        cu=super.subseq(0..-1)
        cu.pos=OFFSET
        cu
      end
    end
    class SubSeq2 <Indexed
      def a_seq
        seq= Sequence::Indexed.new("0123456789#{DATA}0123456789")
        seq = seq. subseq(10...-10)
        seq.pos=OFFSET
        return seq
      end
    end
    class SubSeq3 <Indexed
      def a_seq
        seq = Sequence::Indexed.new("0123456789#{DATA}0123456789")
        seq = seq. subseq(10,DATA.size)
        seq.pos=OFFSET
        return seq
      end
    end
    class Reversed <Indexed
      def a_seq
        seq =DATA.reverse.to_sequence.reversed
        seq.pos=12
        seq
      end
    end
    class Circular <Indexed
      def a_seq
        seq = Sequence::Circular.new(super,OFFSET)
      end
      undef_method(:test_nearbegin, :test_nearend)
      def absolutes_always_fail; true end
      def randlimit; DATA.size end
    end
    nil&& #disabled for now.... too many size dependancies in tests
    class Big <Indexed 
      def a_seq
        seq = Sequence::Indexed.new(DATA.gsub(/[ \n]/,' '*1000+"\\1"))
        seq.move(OFFSET+2000)
        return seq
      end
      undef_method :test_pos
    end
    class Tempfile <Indexed
      @@seq =nil
      @@count=0
      def a_seq
        @@seq and @@seq.data.close(true)    

        tf=::Tempfile.new("test_seq#@@count"); @@count+=1
       
        tf.write DATA

        tf.pos=OFFSET
        @@seq = Sequence::File.new tf
        @@seq.goto OFFSET
        @@seq
      end
      undef_method(:test_insert,:test_delete,:test_modify,:test_insert_empty,:test_delete_empty,:test_insert_start,:test_delete_start,:test_insert_end,:test_delete_end,:test_randomized_methods_some_more)
      undef_method    :test_modify_and_read_joints, :test_pos_munging
      undef_method    :test_write_and_read_joints, :test_insert_and_read_joints, :test_delete_and_read_joint
    end
    
    class List < Indexed
      def a_seq
      
        seq = Sequence::List.new(DATA.scan(/.{1,8}/m).map{|str| str.to_sequence})
        seq.pos=OFFSET
        seq
      end

      def test__lookup_idx
        seq=a_seq
        (0..DATA.size).map{|i|
          assert_equal i/8, seq._lookup_idx(i)
        }
      end

    end

    class ListMaxxed < Indexed
      def a_seq
      
        seq = Sequence::List.new(DATA.scan(/./m).map{|str| str.to_sequence})
        seq.pos=OFFSET
        seq
      end
      def test__lookup_idx
        seq=a_seq
        (0...DATA.size).map{|i|
          assert_equal i, seq._lookup_idx(i)
        }
      end
    end

    class List1 < Indexed
      def a_seq
      
        seq = Sequence::List.new([DATA.dup.to_sequence])
        seq.pos=OFFSET
        seq
      end
    end
    
    class List2 < Indexed
      def a_seq
        mid=DATA.size/2
        seq = Sequence::List.new(
          [DATA[0...mid].to_sequence,
          DATA[mid..-1].to_sequence]
        )
        seq.pos=OFFSET
        seq
      end
    end

    class ListRandomized < Indexed
      def a_seq
        reuse=defined? @saved_lens
        @saved_lens||=[]
        saved_lens=@saved_lens.dup
        maxchunk=DATA.size/5
        idx=0
        list=[]
        begin
          if reuse
            len=saved_lens.shift
          else
            len=rand(maxchunk)+1
            @saved_lens<<len
          end
          list<<DATA[idx,len].to_sequence
          idx+=len

        end until(idx>=DATA.size)

        seq= Sequence::List.new(list)
        seq.pos=OFFSET
        seq



      end
    end
    
    class IO < Indexed
      def a_seq
        r,w=::IO.pipe
        r=Sequence::IO[r]
        w.write DATA
        r.read(OFFSET)== DATA[0,OFFSET] or raise "predata mismatch inside pipe"
        return r
      end
      
      #need to disable tests that move cursor position back or modify data
      undef_method(*(MOVEPOSMETHODS+MODIFYMETHODS))
    end
    
    module SmallScanBuffered
      SequenceTests.constants.each{|k|
        xk= SequenceTests.const_get(k)
        next unless (xk.is_a? Class and xk<=::SequenceTests::Indexed)
        const_set k, xk=Class.new(xk)
        xk.instance_eval do
          define_method :a_seq do
            result=super()
            result.maxmatchlen=10
            result
          end
        end
      }
    end 

    module ListWrapped
      SequenceTests.constants.each{|k|
        xk= SequenceTests.const_get(k)
        next unless (xk.is_a? Class and xk<=::SequenceTests::Indexed)
        next if /Circular/===xk.name
        const_set k, xk=Class.new(xk)
        xk.instance_eval do
          define_method :a_seq do
            result=Sequence::List.new([wrappee=super()])
            result.pos=wrappee.pos
            return result
          end
        end
      }
    end


    module ListWrappedAndChunkReified
      SequenceTests.constants.each{|k|
        xk= SequenceTests.const_get(k)
        next unless (xk.is_a? Class and xk<=::SequenceTests::Indexed)
        next if /Circular/===xk.name
        const_set k, xk=Class.new(xk)
        xk.instance_eval do
          define_method :a_seq do
            result=Sequence::List.new([wrappee=super()])
            chunk=rand_pos_pair
            chunk=chunk.first..chunk.last
            result[chunk]=result[chunk]
            result.pos=wrappee.pos
            return result
          end
        end
      }
      class ListMaxxed
        undef test__lookup_idx
      end
      class List
        undef test__lookup_idx
      end
      class IO
        def test_size; end  #why can't i just undef it? dunno...
      end

    end


 
=begin disabled for now; too many failures
     module Buffered
      SequenceTests.constants.each{|k|
        oxk= SequenceTests.const_get(k)
        next unless (oxk<=Indexed rescue nil)
        const_set k, xk=Class.new(SequenceTests::Indexed)
        xk.instance_eval do
          define_method :a_seq do
            #p [::Sequence::Buffered, oxk]
            ::Sequence::Buffered.new(oxk.allocate.a_seq)
          end
        end
      }
    end 
 
     module Shifting
      SequenceTests.constants.each{|k|
        oxk= SequenceTests.const_get(k)
        next unless Class===oxk
        const_set k, xk=Class.new(SequenceTests::Indexed)
        xk.instance_eval do
          define_method :a_seq do
            #p [::Sequence::Shifting, oxk]
            ::Sequence::Shifting.new(oxk.allocate.a_seq)
          end
        end
      }
    end 
=end
 
    class Indexed
      undef_method(*(MOVEPOSMETHODS+MODIFYMETHODS))
    def test_optional_capture
       seq=a_seq
       word=seq.scan /(more of )?that (tough)/
       md=seq.last_match
       assert_equal "that tough", word
       assert_equal "that tough", md[0]
       assert_equal nil, md[1]
       assert_equal "tough", md[2]
        
       assert_equal OFFSET, md.begin(0)
       assert_equal OFFSET+10, md.end(0)
       assert_equal nil, md.begin(1)
       assert_equal nil, md.end(1)
       assert_equal OFFSET+5, md.begin(2)
       assert_equal OFFSET+10, md.end(2)

    end


    RANDOMIZED_METHODS=[:test_slice,:test_insert,:test_delete,:test_modify]
    def test_randomized_methods_some_more n=50
      RANDOMIZED_METHODS.each{|m| n.times{send m}}  
    end
    
    def rand_pos_pair
      [rand(randlimit),rand(randlimit)].sort
    end
    
    def randlimit 
      DATA.size+1
    end
    
    
    def test_pos_munging
      (1..3).each{|n|
      seq=a_seq
      assert_equal OFFSET, seq.pos
      seq[seq.pos-4,seq.pos+4]="oook"*n
      assert_equal OFFSET-4, seq.pos
      }      
    
    end
    
    def test_slice_empty; test_slice 0,0 end
    
    def test_slice first=nil, last=nil
      seq =a_seq
      
      first or (first,last=*rand_pos_pair)
    
      assert_equal DATA[first...last], seq[first...last]
      assert_equal DATA[first..last], seq[first..last]
      assert_equal DATA[first,last-first], seq[first,last-first]
      assert_equal DATA[first..last], seq[first..last]
      assert_equal DATA[first], seq[first]

      assert_equal( (DATA.slice first...last), (seq.slice first...last) )
      assert_equal( (DATA.slice first..last), (seq.slice first..last) )
      assert_equal( (DATA.slice first,last-first), (seq.slice first,last-first) )
      assert_equal( (DATA.slice first..last), (seq.slice first..last) )
      assert_equal( (DATA.slice first), (seq.slice first) )
    end
    
    
    

    def test_size
      assert_equal DATA.size, a_seq.size
    end
    
    def test_read
      seq =a_seq
      assert_equal 'that t', (seq.read 6)
      assert_equal OFFSET+6, seq.pos
    end

    def test_readahead
      seq =a_seq
      assert_equal 'that t', (seq.readahead 6)
      assert_equal OFFSET, seq.pos
    end

    def test_pos
      seq =a_seq
      assert_equal OFFSET, seq.pos
    end    

    def test_pos=
      seq =a_seq
      assert_equal OFFSET, seq.pos
      seq.pos=25
      assert_equal 25, seq.pos
      assert_equal 'y talk', (seq.read 6)
      assert_equal 31, seq.pos
    end
    
    def test_nearbegin
      seq =a_seq
      seq.pos=5
      assert seq.nearbegin(10)
      assert ! seq.nearbegin(4)
    end    
 
    def test_nearend
      seq =a_seq
      seq.pos=-5
      assert seq.nearend(10)
      assert ! seq.nearend(4)
    end
    
    def test_write
      seq =a_seq
      assert_equal 17, seq.write("gooblesnortembopy")
      assert_equal OFFSET+17, seq.pos
      seq.pos=OFFSET
      assert_equal "gooblesnortembopy", (seq.read 17)
      assert_raises(ArgumentError) { seq.write("gooblesnortembopy"*10) }
    end
    
    def test_write_and_read_joints
      table=[[:write,+5], [:writeahead,+0], [:writeback,-0.1], [:writebehind,-5]]
      table.each do|(mname,offs)|
        seq =a_seq
        offs<0 and offs=-offs and seq.move 5
        assert_equal 5, seq.send( mname, ("snark") )
        assert_equal OFFSET+offs.to_i, seq.pos
  #      seq.pos=OFFSET
        assert_equal "baz sn", seq[OFFSET-4,6]
        assert_equal "rktoug", seq[OFFSET+3,6]
        assert_equal OFFSET+offs.to_i, seq.pos
      end
    end
    
    def test_modify_and_read_joints
        seq =a_seq
#        seq.pos+=2
        assert_equal OFFSET, seq.pos
        assert_equal "snark", seq.modify(15..25,"snark")
        assert_equal OFFSET, seq.pos
  #      seq.pos=OFFSET
        assert_equal "thasna", seq[12,6]
        assert_equal "rk tal", seq[18,6]
    end
    
    
    def test_insert_and_read_joints
        seq =a_seq
        assert_equal "snark", seq.insert(seq.pos,"snark") 
        assert_equal OFFSET, seq.pos
  #      seq.pos=OFFSET
        assert_equal "baz sn", seq[OFFSET-4,6]
        assert_equal "rkthat", seq[OFFSET+3,6]
        assert_equal OFFSET, seq.pos
        assert_equal "snark", seq.read(5)
        assert_equal OFFSET+5, seq.pos
    end
    
    def test_delete_and_read_joint
        seq =a_seq
        assert_equal nil, seq.delete(seq.pos,5) 
        assert_equal OFFSET, seq.pos
  #      seq.pos=OFFSET
        assert_equal "baz to", seq[OFFSET-4,6]
        assert_equal OFFSET, seq.pos
        assert_equal "tough", seq.read(5)
        assert_equal OFFSET+5, seq.pos
    end
    
    def test_writeback
      seq =a_seq
      assert_equal 6, seq.writeback("gooble") 
      assert_equal OFFSET-6, seq.pos
      seq.pos=OFFSET
      assert_equal "gooble", (seq.readback 6)
      assert_raises(ArgumentError) { seq.writeback("gooblesnortembopy") }
    end
    
    def change_notification(seq,first,oldlen,newlen)
      assert_same @seq, seq
      assert_equal @first, first
      assert_equal @oldlen, oldlen
      assert_equal @newlen, newlen
      @changes_seen +=1
    end
    
    def add_test_listener(seq,first,last,newlen)
      @changes_seen=0
      if first<0 
        first+=seq.size
        last.zero? and last=seq.size
      end
      last<0 and last+=seq.size
      @seq,@first,@oldlen,@newlen= seq,first,last-first,newlen
      seq.on_change_notify(self)
    end
    
    def verify_test_listener expect_count=1
      assert_equal @seq.instance_eval{@change_listeners}.to_a, [self]
      if expect_count!=@changes_seen
      assert_equal @seq.instance_eval{@change_listeners}.to_a, [self]
      assert false
      end
      assert_equal @seq.instance_eval{@change_listeners}.to_a, [self]
    end
    
    def test_insert_empty; test_insert 15,15 end
    def test_insert_start; test_insert 0,15 end
    def test_insert_end; test_insert( -15,0 ) end
    
    def test_insert(first=nil,last=nil)
      seq =a_seq
      first or (first,last=*rand_pos_pair)
#      puts("first=#{first}, last=#{last}")
      len=last-first
      add_test_listener seq,first,first,len
      assert_equal seq.instance_eval{@change_listeners}.to_a, [self]
      seq.insert first, " "*len
      assert_equal seq.instance_eval{@change_listeners}.to_a, [self]
      verify_test_listener(1)
    end

    
    def test_delete_empty; test_delete 15,15 end
    def test_delete_start; test_delete 0,15 end
    def test_delete_end; test_delete( -15,0 ) end
    
    
    def test_delete first=nil,last=nil
      seq =a_seq
      first or (first,last=*rand_pos_pair)
#      puts "first=#{first}, last=#{last}"
      len=last-first
      add_test_listener seq,first,last,0
      list=seq.instance_eval{@change_listeners}.to_a
      assert_equal 1, list.size
      assert_equal self.__id__, list.first.__id__
      seq.delete first, len
      assert_equal 1, list.size
      assert_equal self.__id__, list.first.__id__
      verify_test_listener(1)
    end
    
    
    def test_modify
      seq =a_seq
      first,last=*rand_pos_pair
      oldlen=last-first
      newlen=rand(2*DATA.size)
      add_test_listener seq,first,last,newlen
      #puts "first: #{first}, oldlen: #{oldlen}, newlen: #{newlen}"
      assert_equal seq.instance_eval{@change_listeners}.to_a, [self]
      seq.modify first, oldlen," "*newlen
      assert_equal seq.instance_eval{@change_listeners}.to_a, [self]
      verify_test_listener(1)
    end
    
    
    def verify_failmatch_status(meth,pat,pos=nil)
     _=(seq =a_seq).send meth,pat
     pos ? seq.pos=pos : pos=OFFSET
      assert_equal nil, _
      assert_equal pos, seq.pos
      assert       seq.last_match.nil?
    end
    
    def verify_aftermatch_status(seq,pos,matches,starts,pre,post,eof)
      assert_equal pos, seq.pos
      assert       seq.last_match
      i=nil
      matches.each_with_index{|m,i| 
        assert_equal m, seq.last_match[i]
      }
      assert_equal nil, seq.last_match[i+1]
      assert_equal matches.length, seq.last_match.length
      assert_equal matches, seq.last_match.to_a
      starts.each_with_index{|start,i| 
        assert_equal start, seq.last_match.begin(i)
        assert_equal start+matches[i].size, seq.last_match.end(i)
        
        assert_equal start, seq.last_match.offset(i).first
        assert_equal start+matches[i].size, seq.last_match.offset(i).last
      }
      assert_equal nil, seq.last_match.begin(i+1)
      assert_equal nil, seq.last_match.end(i+1)
      assert_equal nil, seq.last_match.offset(i+1)
      
      assert_equal pre, seq.last_match.pre_match[0..-1]
      assert_equal post, seq.last_match.post_match[0..-1]
      eof and assert seq.last_match.post_match.eof?
    end
    
    def verify_scan_methods(rex,offset,matchstr,restargs,backwards=false)
      mappings={  
         :scan=>[:to_s,1], :check =>[:to_s,0],
         :skip=>[:size,1], :match? =>[:size,0],



         :scan_until=>[:to_s,1], :check_until=>[:to_s,0],
         :skip_until=>[:size,1], :exist? =>[:size,0],      
      }
      
      mappings.each{|k,v| 
        k=k.to_s.sub(/(_until|\?)?$/) {"back"+$1} if backwards
        seq =a_seq
        seq.pos=offset
        assert_equal matchstr.send( v[0]), seq.send( k, rex)
        factor=v[1]
        factor=-factor if backwards
        verify_aftermatch_status(seq,
            offset+matchstr.size*factor,   *restargs
        )
      }
    end

    def verify_scan_until_methods rex,offset,prematch,matchstr,restargs
      restargs[1][0]==offset and return verify_scan_methods( rex,offset,matchstr,restargs )
      mappings={  
         :scan_until=>[:to_s,1],
         :check_until=>[:to_s,0],
         :skip_until=>[:size,1],
         :exist? =>[:size,0]      
      }
      
      mappings.each{|k,v| 
    
        (seq =a_seq)
        seq.pos=offset
        assert_equal prematch.send(v[0])+matchstr.send(v[0]), seq.send( k, rex)
        verify_aftermatch_status(        seq,offset+(prematch.size+matchstr.size)*v[1],*restargs      )
      }
      
      
      %w[scan skip check match?].each{|meth| 
        verify_failmatch_status( meth,rex,offset )
      }
    end

    def test_scanning
  
      assert_equal "that ", a_seq.readahead(5)

      verify_scan_methods( /th(is|at)/,OFFSET,"that",
        [%W[that at],[OFFSET,OFFSET+2], 
         "", " tough guy talk\ndon't make you a dog", false] )
#=begin
      _=(seq =a_seq).scan /th(is|at)/
      assert_equal "that", _
      verify_aftermatch_status(
        seq,16,%W[that at],[OFFSET,OFFSET+2],
        "", " tough guy talk\ndon't make you a dog", false
      )
      
      _=(seq =a_seq).check /th(is|at)/
      assert_equal "that", _
      verify_aftermatch_status(
        seq,12,%W[that at],[OFFSET,OFFSET+2],
        "", " tough guy talk\ndon't make you a dog", false
      )
      
      _=(seq =a_seq).skip /th(is|at)/
      assert_equal 4, _
      verify_aftermatch_status(
        seq,16,%W[that at],[OFFSET,OFFSET+2],
        "", " tough guy talk\ndon't make you a dog", false
      )
      
      _=(seq =a_seq).match? /th(is|at)/
      assert_equal 4, _
      verify_aftermatch_status(
        seq,12,%W[that at],[OFFSET,OFFSET+2],
        "", " tough guy talk\ndon't make you a dog", false
      )
#=end      
      
      verify_scan_until_methods( /[mb]ake/, OFFSET, "that tough guy talk\ndon't ", "make",
        [%W[make],[OFFSET+26],
        "that tough guy talk\ndon't "," you a dog", false] )
  
#=begin          
      _=(seq =a_seq).scan_until /[mb]ake/
      assert_equal "that tough guy talk\ndon't make", _
      verify_aftermatch_status(
        seq,16+26,%W[make],[OFFSET+26],
        "that tough guy talk\ndon't "," you a dog", false
      )

      _=(seq =a_seq).check_until /[mb]ake/
      assert_equal "that tough guy talk\ndon't make", _
      verify_aftermatch_status(
        seq,OFFSET,%W[make],[OFFSET+26],
        "that tough guy talk\ndon't "," you a dog", false
      )

      _=(seq =a_seq).skip_until /[mb]ake/
      assert_equal 30, _
      verify_aftermatch_status(
        seq,16+26,%W[make],[OFFSET+26],
        "that tough guy talk\ndon't "," you a dog", false
      )
      
      _=(seq =a_seq).exist? /[mb]ake/
      assert_equal 30, _
      verify_aftermatch_status(
        seq,OFFSET,%W[make],[OFFSET+26],
        "that tough guy talk\ndon't "," you a dog", false
      )
#=end      
      
      #ok, and now with anchors
      verify_failmatch_status :scan_until, /[cr]at\Z/
      verify_failmatch_status :scan_until, /you\Z/
      verify_failmatch_status :scan_until, /talk\Z/

      verify_failmatch_status :exist?, /[cr]at\Z/
      verify_failmatch_status :exist?, /you\Z/
      verify_failmatch_status :exist?, /talk\Z/

      verify_failmatch_status :check_until, /[cr]at\Z/
      verify_failmatch_status :check_until, /you\Z/
      verify_failmatch_status :check_until, /talk\Z/
      
      verify_failmatch_status :skip_until, /[cr]at\Z/
      verify_failmatch_status :skip_until, /you\Z/
      verify_failmatch_status :skip_until, /talk\Z/
      
      unless absolutes_always_fail
      verify_scan_until_methods( /(d([^d]+))\Z/,OFFSET,"",      "that tough guy talk\ndon't make you a dog",
      [%W[dog dog og],[OFFSET+37,OFFSET+37,OFFSET+38],"that tough guy talk\ndon't make you a ", "", true] )

#=begin      
      _=(seq =a_seq).scan_until /(d([^d]+))\Z/
      assert_equal "that tough guy talk\ndon't make you a dog", _
      verify_aftermatch_status(
        seq,52,%W[dog dog og],[49,49,50],
        "that tough guy talk\ndon't make you a ","", true
      )      
      
      _=(seq =a_seq).exist? /(d([^d]+))\Z/
      assert_equal 40, _
      verify_aftermatch_status(
        seq,OFFSET,%W[dog dog og],[49,49,50],
        "that tough guy talk\ndon't make you a ","", true
      )      
      
      _=(seq =a_seq).check_until /(d([^d]+))\Z/
      assert_equal "that tough guy talk\ndon't make you a dog", _
      verify_aftermatch_status(
        seq,12,%W[dog dog og],[49,49,50],
        "that tough guy talk\ndon't make you a ","", true
      )      

      _=(seq =a_seq).skip_until /(d([^d]+))\Z/
      assert_equal 40, _
      verify_aftermatch_status(
        seq,52,%W[dog dog og],[49,49,50],
        "that tough guy talk\ndon't make you a ","", true
      )      
#=end
      end

      #implicitly anchored with anchors
      verify_failmatch_status :scan, /[cr]at\Z/,49
      verify_failmatch_status :scan, /you\Z/,43
      verify_failmatch_status :scan, /talk\Z/,31
      
      verify_failmatch_status :check, /[cr]at\Z/,49
      verify_failmatch_status :check, /you\Z/,43
      verify_failmatch_status :check, /talk\Z/,31
      
      verify_failmatch_status :skip, /[cr]at\Z/,49
      verify_failmatch_status :skip, /you\Z/,43
      verify_failmatch_status :skip, /talk\Z/,31
      
      verify_failmatch_status :exist?, /[cr]at\Z/,49
      verify_failmatch_status :exist?, /you\Z/,43
      verify_failmatch_status :exist?, /talk\Z/,31

      unless absolutes_always_fail
      verify_scan_methods( /(d([^d]+))\Z/,OFFSET+37,   "dog",
      [%W[dog dog og],[OFFSET+37,OFFSET+37,OFFSET+38],"", "", true] )


#=begin    
  _=(seq =a_seq)
      seq.pos=49 #at 'dog'
      _= seq.scan /(d([^d]+))\Z/
      assert_equal "dog", _
      verify_aftermatch_status(
        seq,52,%W[dog dog og],[49,49,50],"","", true
      )      
      
      _=(seq =a_seq)
      seq.pos=49 #at 'dog'
      _= seq.match? /(d([^d]+))\Z/
      assert_equal 3, _
      verify_aftermatch_status(
        seq,49,%W[dog dog og],[49,49,50],"","", true
      )      
      
      _=(seq =a_seq)
      seq.pos=49 #at 'dog'
      _= seq.check /(d([^d]+))\Z/
      assert_equal "dog", _
      verify_aftermatch_status(
        seq,49,%W[dog dog og],[49,49,50],"","", true
      )      
            
      _=(seq =a_seq)
      seq.pos=49 #at 'dog'
      _= seq.skip /(d([^d]+))\Z/
      assert_equal 3, _
      verify_aftermatch_status(
        seq,52,%W[dog dog og],[49,49,50],"","", true
      )  
#=end
      end
      #$ as anchor
      verify_failmatch_status :scan_until, /[cr]at$/
      verify_failmatch_status :scan_until, /you$/

      verify_failmatch_status :exist?, /[cr]at$/
      verify_failmatch_status :exist?, /you$/
      
      verify_failmatch_status :check_until, /[cr]at$/
      verify_failmatch_status :check_until, /you$/
      
      verify_failmatch_status :skip_until, /[cr]at$/
      verify_failmatch_status :skip_until, /you$/
      
      unless absolutes_always_fail
      verify_scan_until_methods( /(d([^d]+))$/,OFFSET,"",      "that tough guy talk\ndon't make you a dog",
      [%W[dog dog og],[OFFSET+37,OFFSET+37,OFFSET+38],"that tough guy talk\ndon't make you a ", "", true] )


#=begin
      _=(seq =a_seq).scan_until /(d([^d]+))$/
      assert_equal "that tough guy talk\ndon't make you a dog", _
      verify_aftermatch_status(
        seq,52,%W[dog dog og],[49,49,50],
        "that tough guy talk\ndon't make you a ","", true
      )      
      
      _=(seq =a_seq).exist? /(d([^d]+))$/
      assert_equal 40, _
      verify_aftermatch_status(
        seq,OFFSET,%W[dog dog og],[49,49,50],
        "that tough guy talk\ndon't make you a ","", true
      )      
      
      _=(seq =a_seq).check_until /(d([^d]+))$/
      assert_equal "that tough guy talk\ndon't make you a dog", _
      verify_aftermatch_status(
        seq,12,%W[dog dog og],[49,49,50],
        "that tough guy talk\ndon't make you a ","", true
      )      
      
      _=(seq =a_seq).skip_until /(d([^d]+))$/
      assert_equal 40, _
      verify_aftermatch_status(
        seq,52,%W[dog dog og],[49,49,50],
        "that tough guy talk\ndon't make you a ","", true
      )      
#=end
      end
            
      verify_scan_until_methods( /(st|[bt])alk$/,OFFSET,"",      "that tough guy talk",
      [%W[talk t],[OFFSET+15,OFFSET+15],"that tough guy ","\ndon't make you a dog", false] )
#=begin
      _=(seq =a_seq).scan_until /(st|[bt])alk$/
      assert_equal "that tough guy talk", _
      verify_aftermatch_status(seq,31,%W[talk t],[27,27],"that tough guy ","\ndon't make you a dog",false)
      
      _=(seq =a_seq).exist? /(st|[bt])alk$/
      assert_equal 19, _
      verify_aftermatch_status(seq,12,%W[talk t],[27,27],"that tough guy ","\ndon't make you a dog",false)
      
      _=(seq =a_seq).check_until /(st|[bt])alk$/
      assert_equal "that tough guy talk", _
      verify_aftermatch_status(seq,12,%W[talk t],[27,27],"that tough guy ","\ndon't make you a dog",false)
      
      _=(seq =a_seq).skip_until /(st|[bt])alk$/
      assert_equal 19, _
      verify_aftermatch_status(seq,31,%W[talk t],[27,27],"that tough guy ","\ndon't make you a dog",false)
#=end      
      verify_failmatch_status :scan_until, /(bob|talk\Z|(dou(gh)?))/
      verify_failmatch_status :check_until, /(bob|talk\Z|(dou(gh)?))/
      verify_failmatch_status :skip_until, /(bob|talk\Z|(dou(gh)?))/
      verify_failmatch_status :exist?, /(bob|talk\Z|(dou(gh)?))/
      
      verify_scan_until_methods( /(bob|you\Z|(tou(gh)?))/,OFFSET, "", "that tough",
      [%W[tough tough tough gh],[OFFSET+5,OFFSET+5,OFFSET+5,OFFSET+8],"that "," guy talk\ndon't make you a dog", false] )
      
      _=(seq =a_seq).scan_until( /(bob|you\Z|(tou(gh)?))/ )
      assert_equal "that tough", _
      verify_aftermatch_status(seq,22,%W[tough tough tough gh],[17,17,17,20],"that "," guy talk\ndon't make you a dog",false)
      
      _=(seq =a_seq).check_until( /(bob|you\Z|(tou(gh)?))/ )
      assert_equal "that tough", _
      verify_aftermatch_status(seq,12,%W[tough tough tough gh],[17,17,17,20],"that "," guy talk\ndon't make you a dog",false)
      
      
      _=(seq =a_seq).skip_until( /(bob|you\Z|(tou(gh)?))/ )
      assert_equal 10, _
      verify_aftermatch_status(seq,22,%W[tough tough tough gh],[17,17,17,20],"that "," guy talk\ndon't make you a dog",false)
      
      
      _=(seq =a_seq).exist?( /(bob|you\Z|(tou(gh)?))/ )
      assert_equal 10, _
      verify_aftermatch_status(seq,12,%W[tough tough tough gh],[17,17,17,20],"that "," guy talk\ndon't make you a dog",false)
      
      
      
      
      
      seq =a_seq
      _=seq.scanback( /baz $/ )
      assert_equal "baz ",_
      verify_aftermatch_status(seq,8,["baz "],[8],"foo\nbar ","",false)
    end
    end
  end




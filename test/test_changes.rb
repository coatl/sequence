# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.
$VERBOSE=1
    require 'test/unit'
   # require 'rubygems'
    require 'sequence'
    require 'sequence/indexed'
   
         class TC_NilContentsTest < Test::Unit::TestCase
           def setup
            @c=Sequence::Indexed.new([1,2,3,nil,4,5,6])
           end
     
           # def teardown
           # end
     
           def test_nilcontents
             @c.pos=0
             assert_equal(7,@c.size)
             assert_equal([1,2,3],@c.read(3))
             assert(!@c.eof?)
             assert_equal([nil],@c.read(1))
             assert_equal([4,5,6],@c.read(3))
             assert(@c.eof?)
             assert_equal([],@c.read(3))
             assert(@c.eof?)
             assert_equal(7,@c.pos)
           end
         end


        class TC_ChangeListTest #< Test::Unit::TestCase
           def setup
            @c= Sequence::Indexed.new([1,2,3,nil,4,5,6])
            @chgs= [0...0,[0], 1..2,[20,25,30], 3,[3.5], 4,[], 5..6,[50], 7,[70,80]]
           end
     

          def test_changelist
            @c.changelist(*@chgs)
            assert_equal @c.data!, [0,1,20,25,30,3.5,50,70,80]
          end

        end

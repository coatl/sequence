# Copyright (C) 2006, 2011  Caleb Clausen
# Distributed under the terms of Ruby's license.
$VERBOSE=1

require 'test/unit'
require 'sequence/indexed' 
 
module Sequence::StringLike
  public :group_anchors
end

  class SimpleScanUntil < Test::Unit::TestCase
    def test_scan_until

      cu= Sequence::Indexed.new('1234')

#      assert_equal '#Sequence::OfString: @data="1234" @pos=0 >', cu.inspect
      assert cu.is_a?(Sequence::OfString)
      assert_equal ["1234",0], cu.instance_eval{[@data,@pos]}


      _=cu.scan_until(/3/)
      assert_equal '123',_
      assert_equal 3, cu.pos
      assert_equal '4', cu.last_match.post_match.read(1)
      assert_equal 3, cu.pos
    end
  end
 
  class GroupAnchorsExhaustive < Test::Unit::TestCase
    def setup;       @cu= Sequence::OfString.new'' end

    def test_unnamed 
    assert_nothing_thrown do
 
      _=@cu.group_anchors(/asdfdfs$/,nil)
      assert_equal "[/(?-mix:asdfdfs(?=\n))/, []]", _.inspect

      _=@cu.group_anchors(/asdf(df)s$/,nil)
      assert_equal "[/(?-mix:asdf(df)s(?=\n))/, []]", _.inspect

      _=@cu.group_anchors(/(\Z|asdf(df)s)$/,nil)
      assert_equal "[/(?-mix:((?!)|asdf(df)s)(?=\n))/, []]", _.inspect

     _=@cu.group_anchors(/(\Z|asdf(df)s)$/,nil)
      assert_equal "[/(?-mix:((?!)|asdf(df)s)(?=\n))/, []]", _.inspect

      _=@cu.group_anchors(/(\Z|asdf(df)s)$/,true)
      assert_equal "[/(\\Z|asdf(df)s)$/, []]", _.inspect

      _=@cu.group_anchors(/(\A|^asdf(df)s)/,true)
      assert_equal "[/(?-mix:((?!)|(^)asdf(df)s))/, [2]]", _.inspect

      _=@cu.group_anchors(/(\A|^asdf(df)s)/,nil)
      assert_equal "[/(\\A|^asdf(df)s)/, []]", _.inspect


      _=@cu.group_anchors(/(\A|^asdf(df)s)/,true)
      assert_equal "[/(?-mix:((?!)|(^)asdf(df)s))/, [2]]", _.inspect


      _=@cu.group_anchors(/(\A|\^asdf(df)s)/,true)
      assert_equal "[/(?-mix:((?!)|\\^asdf(df)s))/, []]", _.inspect

      _=@cu.group_anchors(/(\\A|^asdf(df)s)/,nil)
      assert_equal "[/(\\\\A|^asdf(df)s)/, []]", _.inspect

      _=@cu.group_anchors(/(\\A|^asdf(df)s)/,true)
      assert_equal "[/(?-mix:(\\\\A|(^)asdf(df)s))/, [2]]", _.inspect


      _=@cu.group_anchors(/([\A]|^asdf(df)s)/,true)
      assert_equal "[/(?-mix:([\\A]|(^)asdf(df)s))/, [2]]", _.inspect

      _=@cu.group_anchors(/(\A|[z^]asdf(df)s)/,nil)
      assert_equal "[/(\\A|[z^]asdf(df)s)/, []]", _.inspect

      _=@cu.group_anchors(/(\A|[z^]asdf(df)s)/,true)
      assert_equal "[/(?-mix:((?!)|[z^]asdf(df)s))/, []]", _.inspect

      _=@cu.group_anchors(/([\A]|^asdf(df)s)/,nil)
      assert_equal "[/([\\A]|^asdf(df)s)/, []]", _.inspect


      #yuck! supporting old ruby versions (<2.0) in this block.
      #maybe just delete this?
        begin
          eval %{  /[[]/  }
        rescue SyntaxError
          open_bracket_in_char_class_needs_bs=true
        end
        oldVERBOSE=$VERBOSE
        $VERBOSE=nil
        eval <<-'END' unless open_bracket_in_char_class_needs_bs
          _=@cu.group_anchors(/([\A[~]|^asdf(df)s)/,true)
          assert_equal "[/(?-mix:([\\A[~]|(^)asdf(df)s))/, [2]]", _.inspect

          _=@cu.group_anchors(/(\A|[z^[~]asdf(df)s)/,nil)
          assert_equal "[/(\\A|[z^[~]asdf(df)s)/, []]", _.inspect

          _=@cu.group_anchors(/(\A|[z^[~]asdf(df)s)/,true)
          assert_equal "[/(?-mix:((?!)|[z^[~]asdf(df)s))/, []]", _.inspect

          _=@cu.group_anchors(/([\A[~]|^asdf(df)s)/,nil)
          assert_equal "[/([\\A[~]|^asdf(df)s)/, []]", _.inspect
        END
        $VERBOSE=oldVERBOSE

      _=@cu.group_anchors(/([\A\[~]|^asdf(df)s)/,true)
      assert_equal "[/(?-mix:([\\A\\[~]|(^)asdf(df)s))/, [2]]", _.inspect
	
      _=@cu.group_anchors(/(\A|[z^\[~]asdf(df)s)/,nil)
      assert_equal "[/(\\A|[z^\\[~]asdf(df)s)/, []]", _.inspect
	
      _=@cu.group_anchors(/(\A|[z^\[~]asdf(df)s)/,true)
      assert_equal "[/(?-mix:((?!)|[z^\\[~]asdf(df)s))/, []]", _.inspect

      _=@cu.group_anchors(/([\A\[~]|^asdf(df)s)/,nil)
      assert_equal "[/([\\A\\[~]|^asdf(df)s)/, []]", _.inspect


      _=@cu.group_anchors(/([\A(]|^asdf(df)s)/,true)
      assert_equal "[/(?-mix:([\\A(]|(^)asdf(df)s))/, [2]]", _.inspect

      _=@cu.group_anchors(/(\A|[z^(]asdf(df)s)/,nil)
      assert_equal "[/(\\A|[z^(]asdf(df)s)/, []]", _.inspect

      _=@cu.group_anchors(/(\A|[z^(]asdf(df)s)/,true)
      assert_equal "[/(?-mix:((?!)|[z^(]asdf(df)s))/, []]", _.inspect

      _=@cu.group_anchors(/([\A(]|^asdf(df)s)/,nil)
      assert_equal "[/([\\A(]|^asdf(df)s)/, []]", _.inspect


      _=@cu.group_anchors(/([\A)]|^asdf(df)s)/,true)
      assert_equal "[/(?-mix:([\\A)]|(^)asdf(df)s))/, [2]]", _.inspect

      _=@cu.group_anchors(/(\A|[z^)]asdf(df)s)/,nil)
      assert_equal "[/(\\A|[z^)]asdf(df)s)/, []]", _.inspect

      _=@cu.group_anchors(/(\A|[z^)]asdf(df)s)/,true)
      assert_equal "[/(?-mix:((?!)|[z^)]asdf(df)s))/, []]", _.inspect

      _=@cu.group_anchors(/([\A)]|^asdf(df)s)/,nil)
      assert_equal "[/([\\A)]|^asdf(df)s)/, []]", _.inspect


      _=@cu.group_anchors(/([\A\]]|^asdf(df)s)/,true)
      assert_equal "[/(?-mix:([\\A\\]]|(^)asdf(df)s))/, [2]]", _.inspect

      _=@cu.group_anchors(/(\A|[z^\]]asdf(df)s)/,nil)
      assert_equal "[/(\\A|[z^\\]]asdf(df)s)/, []]", _.inspect

      _=@cu.group_anchors(/(\A|[z^\]]asdf(df)s)/,true)
      assert_equal "[/(?-mix:((?!)|[z^\\]]asdf(df)s))/, []]", _.inspect

      _=@cu.group_anchors(/([\A\]]|^asdf(df)s)/,nil)
      assert_equal "[/([\\A\\]]|^asdf(df)s)/, []]", _.inspect


      _=@cu.group_anchors(/fdgdsfgdsf/,nil)
      assert_equal "[/fdgdsfgdsf/, []]", _.inspect

      _=@cu.group_anchors(/fdgdsfgdsf/,true)
      assert_equal "[/fdgdsfgdsf/, []]", _.inspect

    end
    end
  end
  class BasicMatchData < Test::Unit::TestCase
    def setup
      @cu="".to_sequence
    end

    def test_unnamed 



      _=md=(//.match'') 

      _=md= Sequence::StringLike::CorrectedMatchData.new
      
      _=md.begins=[10,20,30,40,50]
      assert_equal "[10, 20, 30, 40, 50]", _.inspect

      _=md.ends=[15,25,35,45,55]
      assert_equal "[15, 25, 35, 45, 55]", _.inspect

      _=md.groups=%w[abcde fghij klmno pqrst uvwxy]
      assert_equal "[\"abcde\", \"fghij\", \"klmno\", \"pqrst\", \"uvwxy\"]", _.inspect

      _=md=@cu.fixup_match_result( md,[1,3],3,:post) do end

      _=md.begin 0
      assert_equal "13", _.inspect

      _=md.begin 1
      assert_equal "33", _.inspect

      _=md.begin 2
      assert_equal "53", _.inspect

      _=md.begin 5
      assert_equal "nil", _.inspect

      _=md.begin 4
      assert_equal "nil", _.inspect

      assert_equal ["abcde", "klmno", "uvwxy"],md.to_a
    end
  end

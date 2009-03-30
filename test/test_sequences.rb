#eric's original test code; I can't say I understand it
BEGIN{exit}
#!/bin/env ruby
#
# $Id$
#
# Run this to test non-circular sequences.
# Here is a list of the optional arguments:
#
#  <iterations> : approximate number of times to test each method
#  <seed>       : seed for random number generation (0: none)
#  <classRE>    : regular expression for the classes to test ('': all)
#  <methodRE>   : regular expression for the methods to test ('': all)
#  <flags>      : Combination of bits for various flags
#    1 : disable testing of positions
#    2 : only test with strings/characters
#
# All of the standar Test::Unit auto runner options apply.  The --verbose=<level>
# option is especially useful.  Here are the various levels:
#
#  s[ilent]   : don't display anything
#  p[rogress] : show a progress bar.  Upon fail, show the test and seed.
#  n[ormal]   : show each method (and args) tested
#  v[erbose]  : show each method and the object state (inspect)
#
# If you want to see a demo for a particular method, usually a good command
# line would be something like this:
#
#  ruby sequence/test_sequences.rb --verbose=v 10 0 Indexed '^(<method>|close)$'

require 'sequence/test'
require 'sequence/indexed'
require 'sequence/shifting'
require 'sequence/split'
require 'sequence/linked'
require 'sequence/buffered'
require 'sequence/lined'
require 'sequence/reversed'
require 'stringio'
require 'sequence/io'

# :stopdoc:

class Sequence
class Test
class Sequence < Test
    def self.suite
       # @reject = /to_s/ # because of Sequence::Lined
        $0==__FILE__ ? super(*ARGV) : super()
    end
    def self.seed(before,after)
        seqs = [
            (before+after).to_sequence(before.size),
           Sequence::Shifting.new(after+before,after.size),
           Sequence::Split.new(before.clone,after.reverse),
           Sequence::Linked.new(before.clone,after.reverse),
           Sequence.new(Sequence::Indexed.new(before+after,before.size)),
           Sequence::Buffered.new(
               Sequence::Indexed.new(after.clone),
               Sequence::Indexed.new(before.clone,before.size),
                before.size
            ),
           Sequence::Reversed.new(Sequence::Indexed.new((before+after).reverse,after.size)),
        ]
        if @string = String===before
            io=StringIO.new(before+after)
            io.pos=before.size
            seqs << io.to_sequence
            seqs << Sequence::Buffered.new(
                StringIO.new(after),
               Sequence::Indexed.new(before.clone,before.size),
                before.size
            )
        end
        if rand(2).zero?
            @use_positions = false
            seqs << Sequence.new(Sequence::Indexed.new(before+after,before.size)).position
        else
            @use_positions = @flags[0].zero?
        end
        seqs
    end
    def self.plant
        @characters = @flags[1].nonzero?||rand(2).zero?
        super
    end
    def self.elements
        @flags[1].nonzero? ? [?A,?B,?C] : @characters ? [?\n,?\0,?0] : [false,"",[]]
    end
    def self.empty
        @characters&&(@flags[1].nonzero?||rand(2).zero?) ? "" : []
    end
    def self.reject(name,*args,&block)
        case name
        when :scan_pattern then !@string
        when :scan_pattern_until then !@string
        when :scan_pattern_while then !@string
        end
    end
end
end
end

# :startdoc:



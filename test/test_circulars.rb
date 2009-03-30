#eric's original test code; I can't say I understand it
BEGIN{exit}
#!/bin/env ruby
#
# $Id$
#
# Run this to test circular sequences.
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
#  ruby sequence/test_circulars.rb --verbose=v 10 0 Indexed '^(<method>|close)$'

require 'sequence/test'
require 'sequence/circular'
require 'sequence/indexed'
require 'sequence/circular/indexed'
require 'sequence/circular/shifting'
require 'sequence/circular/split'
require 'sequence/circular/linked'

# :stopdoc:

class Sequence
class Test
class Circulars < Test
    def self.suite
        @reject = /^(scan_until|modify|each|collect!|map!|scan_pattern_(while|until))$/
        $0==__FILE__ ? super(*ARGV) : super()
    end
    def self.seed(before,after)
        sequences = [
           Sequence::Circular::Indexed.new(before+after,before.size),
           Sequence::Circular::Indexed.new(after+before,0),
           Sequence::Circular::Shifting.new(after+before,after.size),
           Sequence::Circular::Split.new(before.clone,after.reverse),
           Sequence::Circular::Linked.new(before.clone,after.reverse),
           Sequence::Circular.new(Sequence::Indexed.new(before+after,before.size)),
        ]
        if rand(2).zero?
            @use_positions = false
            sequences << Sequence::Circular.new(
                   Sequence::Indexed.new(before+after,before.size)
                ).position
        else
            @use_positions = @flags[0].zero?
        end
        sequences
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
        when :position!  then !@use_positions && args[0].nil?
        when :position?  then !@use_positions && args[0].nil? && block.nil?
        end
    end
end
end
end

# :startdoc:



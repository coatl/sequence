#!/usr/bin/env ruby
#Copyright (c) 2011 Caleb Clausen
#--
# $Idaemons: /home/cvs/rb/generator.rb,v 1.8 2001/10/03 08:54:32 knu Exp $
# $RoughId: generator.rb,v 1.10 2003/10/14 19:36:58 knu Exp $
# $Id: generator.rb,v 1.12 2005/12/31 02:56:46 ocean Exp $
#++

#this is a copy of (the newest, fastest) generator.rb from the standard lib,
#with SyncEnumerator removed. -cc

#
# = generator.rb: convert an internal iterator to an external one
#
# Copyright (c) 2001,2003 Akinori MUSHA <knu@iDaemons.org>
#
# All rights reserved.  You can redistribute and/or modify it under
# the same terms as Ruby.
#
# == Overview
#
# This library provides the Generator class, which converts an
# internal iterator (i.e. an Enumerable object) to an external
# iterator.  In that form, you can roll many iterators independently.
#
# The SyncEnumerator class, which is implemented using Generator,
# makes it easy to roll many Enumerable objects synchronously.
#
# See the respective classes for examples of usage.


#
# Generator converts an internal iterator (i.e. an Enumerable object)
# to an external iterator.
#
# == Example
#
#   require 'generator'
#
#   # Generator from an Enumerable object
#   g = Generator.new(['A', 'B', 'C', 'Z'])
#
#   while g.next?
#     puts g.next
#   end
#
#   # Generator from a block
#   g = Generator.new { |g|
#     for i in 'A'..'C'
#       g.yield i
#     end
#
#     g.yield 'Z'
#   }
#
#   # The same result as above
#   while g.next?
#     puts g.next
#   end
#   

#if existing Generator library is the slow one, replace with the faster version (above)
require 'generator.rb'
unless Generator.new.instance_variables.include("@loop_thread") 
  remove_const :Generator
class Generator
  include Enumerable

  # Creates a new generator either from an Enumerable object or from a
  # block.
  #
  # In the former, block is ignored even if given.
  #
  # In the latter, the given block is called with the generator
  # itself, and expected to call the +yield+ method for each element.
  def initialize(enum = nil, &block)
    if enum
      @block = proc{|g| enum.each{|value| g.yield value}}
    else
      @block = block
    end
    @index = 0
    @queue = []
    @main_thread = nil
    @loop_thread.kill if defined?(@loop_thread)
    @loop_thread = Thread.new do
      Thread.stop
      begin
        @block.call(self)
      rescue
        @main_thread.raise $!
      ensure
        @main_thread.wakeup
      end
    end
    Thread.pass until @loop_thread.stop?
    self
  end

  # Yields an element to the generator.
  def yield(value)
    if Thread.current != @loop_thread
      raise "should be called in Generator.new{|g| ... }"
    end
    Thread.critical = true
    begin
      @queue << value
      @main_thread.wakeup
      Thread.stop
    ensure
      Thread.critical = false
    end
    self
  end

  # Returns true if the generator has reached the end.
  def end?
    if @queue.empty?
      if @main_thread
        raise "should not be called in Generator.new{|g| ... }"
      end
      Thread.critical = true
      begin
        @main_thread = Thread.current
        @loop_thread.wakeup
        Thread.stop
      rescue ThreadError
        # ignore
      ensure
        @main_thread = nil
        Thread.critical = false
      end
    end
    @queue.empty?
  end

  # Returns true if the generator has not reached the end yet.
  def next?
    !end?
  end

  # Returns the current index (position) counting from zero.
  def index
    @index
  end

  # Returns the current index (position) counting from zero.
  def pos
    @index
  end

  # Returns the element at the current position and moves forward.
  def next
    raise EOFError.new("no more elements available") if end?
    @index += 1
    @queue.shift
  end

  # Returns the element at the current position.
  def current
    raise EOFError.new("no more elements available") if end?
    @queue.first
  end

  # Rewinds the generator.
  def rewind
    initialize(nil, &@block) if @index.nonzero?
    self
  end

  # Rewinds the generator and enumerates the elements.
  def each
    rewind
    until end?
      yield self.next
    end
    self
  end
end
end



if $0 == __FILE__
  eval DATA.read, nil, $0, __LINE__+4
end

__END__

require 'test/unit'

class TC_Generator < Test::Unit::TestCase
  def test_block1
    g = Generator.new { |g|
      # no yield's
    }

    assert_equal(0, g.pos)
    assert_raises(EOFError) { g.current }
  end

  def test_block2
    g = Generator.new { |g|
      for i in 'A'..'C'
        g.yield i
      end

      g.yield 'Z'
    }

    assert_equal(0, g.pos)
    assert_equal('A', g.current)

    assert_equal(true, g.next?)
    assert_equal(0, g.pos)
    assert_equal('A', g.current)
    assert_equal(0, g.pos)
    assert_equal('A', g.next)

    assert_equal(1, g.pos)
    assert_equal(true, g.next?)
    assert_equal(1, g.pos)
    assert_equal('B', g.current)
    assert_equal(1, g.pos)
    assert_equal('B', g.next)

    assert_equal(g, g.rewind)

    assert_equal(0, g.pos)
    assert_equal('A', g.current)

    assert_equal(true, g.next?)
    assert_equal(0, g.pos)
    assert_equal('A', g.current)
    assert_equal(0, g.pos)
    assert_equal('A', g.next)

    assert_equal(1, g.pos)
    assert_equal(true, g.next?)
    assert_equal(1, g.pos)
    assert_equal('B', g.current)
    assert_equal(1, g.pos)
    assert_equal('B', g.next)

    assert_equal(2, g.pos)
    assert_equal(true, g.next?)
    assert_equal(2, g.pos)
    assert_equal('C', g.current)
    assert_equal(2, g.pos)
    assert_equal('C', g.next)

    assert_equal(3, g.pos)
    assert_equal(true, g.next?)
    assert_equal(3, g.pos)
    assert_equal('Z', g.current)
    assert_equal(3, g.pos)
    assert_equal('Z', g.next)

    assert_equal(4, g.pos)
    assert_equal(false, g.next?)
    assert_raises(EOFError) { g.next }
  end

  def test_each
    a = [5, 6, 7, 8, 9]

    g = Generator.new(a)

    i = 0

    g.each { |x|
      assert_equal(a[i], x)

      i += 1

      break if i == 3
    }

    assert_equal(3, i)

    i = 0

    g.each { |x|
      assert_equal(a[i], x)

      i += 1
    }

    assert_equal(5, i)
  end
end

# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.
require 'rubygems'
require 'hoe'
require 'lib/sequence/version.rb'
 
 
 if $*==["test"]
  #hack to get 'rake test' to stay in one process
  #which keeps netbeans happy
  $:<<"lib"
  require "test/test_all.rb"
  Test::Unit::AutoRunner.run
  exit
end
 
   Hoe.new("sequence", Sequence::VERSION) do |_|

     _.author = "Caleb Clausen"
     _.email = "sequence-owner @at@ inforadical .dot. net"
     _.url = [ "http://sequence.rubyforge.org/", "http://rubyforge.org/projects/sequence"]
     _.summary = "A single api for reading and writing sequential data types."
     _.description = <<-END
A unified wrapper api for accessing data in Strings, Arrays, Files, IOs, 
and Enumerations. Each sequence encapsulates some data and a current position 
within it. There are methods for moving the position, reading and writing data
(with or without moving the position) forward or backward from the current
position (or anywhere at all), scanning for patterns (like StringScanner, but 
it works in Files too, among others), and saving a position that will remain
valid even after data is deleted or inserted elsewhere within the sequence. 

There are also some utility classes for making sequences reversed or
circular, turning one-way sequences into two-way, buffering, and making
sequences that are subsets or aggregations of existing sequences. 
     END
   end

   # add other tasks here


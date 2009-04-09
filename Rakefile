# Copyright (C) 2006  Caleb Clausen
# Distributed under the terms of Ruby's license.
require 'rubygems'
require 'hoe'
require 'lib/sequence/version.rb'
 
 
 
 
   Hoe.new("sequence", Sequence::VERSION) do |_|

     _.author = "Caleb Clausen"
     _.email = "sequence-owner @at@ inforadical .dot. net"
     _.url = "http://sequence.rubyforge.org/"
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


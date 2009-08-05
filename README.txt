= sequence

* http://sequence.rubyforge.org/
* http://github.com/coatl/sequence

== DESCRIPTION:
Sequence provides a unified api for access to sequential data types, like
Strings, Arrays, Files, IOs, and Enumerations. Each sequence encapsulates
some data and a current position within it. Some operations apply to data
at (or relative to) the position, others are independant of position. The
api contains operations for moving the position, reading and writing data
(with or without moving the position) forward or backward from the current
position or anywhere, scanning for patterns (like StringScanner, but it
works in Files too, among others), and saving a position that will remain
valid even after data is deleted or inserted elsewhere within the
sequence. 

There are also some utility classes for making sequences reversed or
circular, turning one-way sequences into two-way, buffering, and making
sequences that are subsets or aggregations of existing sequences. 

Sequence is based on Eric Mahurin's Cursor library. I'd like to thank Eric
for Cursor, without which Sequence would not have existed; my design is
very much a derivative of his.


Sequences always fall into one of two broad categories: string-like and
array- like. String-like cursors contain only character data, whereas
Array-like cursors contain objects. 
 


== KNOWN PROBLEMS:
Buffered does not work at all
Shifting's modify methods don't work reliably
No unit tests at all for array-like sequences
(tho Reg's unit test does test OfArray at least somewhat...)

== SYNOPSIS:

  require 'rubygems'
  require 'sequence'
  require 'sequence/indexed'

  seq="........some arbitrary text............".to_sequence
  seq.pos # => 0
  seq.scan_until /some .* text/    # => "........some arbitrary text"
  seq.pos # => 27
  #and much much more

== INSTALL:

* Simply: gem install sequence

== LICENSE:

Copyright (C) 2006,2008  Caleb Clausen  
Distributed under the terms of Ruby's license. (See the file COPYING.)

== USING:

Stuff that's  unworking at the moment is marked with **

Reading a single element:
When any of these operations fail (at beginning/end), nil is returned. 
(Note: nil can also be found inside array-like cursors, so a nil result
doesn't necessarily mean you're at eof.) A name with -back means
backwards, -ahead/-behind means lookahead/lookbehind (pos not moved). 

    #read1       #get next element and advance position
    #readback1   #get previous element and move position back
    #readahead1  #get next element, leaving position alone
    #readbehind1 #get previous element, leaving position alone


Read methods:
These all come in forward and backward forms, and forms that can hold the
position in place. The element sequences are passed/returned in
Array/String like things. 

A note on backwards operations: some methods move the position backward
instead of forward. They operate on data immediately before the position
instead of immediately after. Data is still read or processed in normal
order. To get data in backwards order, use Sequence::Reversed. 

    #read(len)     #read +len+ elements. leaving position after the data read
    #readback(len) #read data behind current position, 
                   #leaving position before the data read.
    
    #readahead(len)    #like read, but position is left alone.
    #readbehind(len)   #like readback, but position is left alone.
    #read!(reverse=false)    # read the remaining elements.

Numeric position methods:
The methods below deal with numeric positions (a pos) to represent the
sequence location. A non-negative number represents the number of elements
from the beginning. A negative number represents the location relative to
the end. 

    #pos    # number of elements from the beginning (0 is at the beginning). 
    #pos?(p)    #  this checks to see if p is a valid numeric position.

    #pos=(p)    # Set #pos to be +p+. 
    #goto p    #go to an absolute position; identical to #pos=

    #move(len)    # move len elements, relative to the current position 
                  #and return distance moved
    
    #move!(reverse=false)    # move to end of the remaining elements 
                             # and return distance moved
    #begin!    #go to beginning
    #end!    #go to end

    #rest_size #number of data items remaining
    #eof?    #are we at past the end of the data, 
             #with no more data ever to arrive?

Sequence::Position methods:

The position methods below use a Sequence::Position to hold the position
rather than simply a numeric position.  These position objects hold a
#pos, which does not change when the parent sequence's position changes.
(Also, the #pos in these objects adjust based on insertions and
deletions.)

    #position(_pos=pos) #returns a Sequence::Position to 
                        #represent the current location.
    #position=(p)       #C Set the position to a Position +p+ (from #position)
    #position?(p)       #  this queries whether a particular #position +p+ 
                        #is valid (is a child or self).
    
    #-(other)  #return new Position decreased by a length or 
               #distance between 2 positions.
    #+(len)    #Returns a new #position increased by +len+ 
               #(positive or negative).

    #succ    # Return a new #position for next location 
             # or +nil+ if we are at the end.
    #pred    # Return a new #position for previous location 
             # or +nil+ if we are at the beginning.

    #begin    # Return a new #position for the beginning.
    #end    # Return a new #position for the end.

    #<=>(other)    # Compare +other+ (a #position) to the current position. 


Access the entire collection: 
    #data,      #return the data underlying the sequence. 
                #the type of the result depends on the sequence type
    
    #data_class #return Array if this sequence can contain any object, 
                #String if it contains only characters
    #new_data   # Return an empty String or Array, 
                #depending on what #data_class is
    
    
    #all_data  #return a String or Array 
               #containing all the data of the sequence

    #size/length    # Returns the number of elements.

    #empty?    # is there any data in the sequence?

    #each     # Performs each just to make this class Enumerable.  
    
    
Random access: 
    #<<(elem)             #append to the end

    #slice/[](index)     # random access to sequence data like in Array/String
    #slice/[](index,len) # random access to sequence data like in Array/String
    #slice/[](range)     # random access to sequence data like in Array/String

Modifying data:
    #slice!              # slice and delete data
    #[]=/modify(sliceargs,newdata)  #replace an arbitrary subsequence 
                                    #with a different one

   #modify has a number of special subcases:
    #insert   -- len is 0 (all existing element are retained)
    #delete   -- newdata.size is 0
    #append   -- insert data after end  
    #prepend  -- insert data before start
    #push/pop -- insert/delete element(s) at end 
    #shift/unshift -- insert/delete elements at start
    #overwrite  -- replacedata.size == len, no shifting needed
    
    #subcases that use the position:
    #(over)write  -- overwrite after current position and move ahead
    #(over)writeback -- overwrite before current position and move back
    #(over)writeahead/behind -- overwrite near location without moving it
    #deletebehind/#deleteahead -- delete before or after the location ** 
    #insertbehind/#insertahead -- insert before or after the location **




Taken from/inspired by StringScanner:
See the StringScanner documentation (ri StringScanner) for a description
of these methods. I have extended StringScanner's interface to take
Strings and character literals (Integers) as well as Regexps. 

About anchors:

When going forward:
  \A ^ match current position
  \Z $ match end of data (String, File, whatever)
When going backward:
  \A ^ match beginning of data
  \Z $ match current position

^ and $ also match at line edges, as usual


My strategy is to rewrite the anchors in the regexp to make them conform
to the desired definition. For instance, \Z is replaced with (?!), unless
the last byte of the file is within the buffer to be compared against, in
which case it is left alone. 

To counter the speed problem, there's a cache so the same regexp doesn't
have to be rewritten more than once. 

about matchdata:
#pre_match/#post_match may not be what you expect; they are Sequences.
#offset contains numeric positions from the very beginning of the Sequence.
                #anchored, forwards
    #scan(pat)  #if pat is right after current position, 
                #advance position and return what pat matched, else nil
    #skip(pat)  #like scan, but returns length instead of match data
    #check(pat) #like scan, but doesn't move position  
    #match?(pat)#like scan, but returns length and doesn't move position
    
                      #unanchored, forwards
    #scan_until(pat)  #scan for pat somewhere after position 
                      #(not necessarily right after)
    #skip_until(pat)  #skip til pattern somewhere after position
    #check_until(pat) #check til pattern somewhere after position
    #exist?(pat)      #does pat exist somewhere after position? if so where?

                      #anchored, backwards
    #scanback(pat)    #scan for pat right before pos
    #skipback(pat)    #skip pat before pos
    #checkback(pat)   #check pat before pos
    #matchback?(pat)  #match pat before pos
    
                      #unanchored, backwards
    #scanback_until(pat)  #scan for pat somewhere before pos
    #skipback_until(pat)  #skip til pat somewhere before pos
    #checkback_until(pat) #check for pat somewhere before pos
    #existback?(pat)      #does pat exist somewhere before pos? if so where?
    
    #skip_literal
    #skip_literals
    
    #skip_until_literal  **
    #skip_until_literals **

    #last_match
    
    #maxmatchlen       #query scan buffer size
    #maxmatchlen= len  #set scan buffer size
    
    #split **
    
    
    #index/#rindex

    #stride **

    #holding    #hold current position while executing a block. 
                #The current pos is passed in.
    #holding?   #like #holding, but position is reset only if 
                #block returns false or nil 
    #holding! &block    #like #holding, but block is instance_eval'd 
                        #in the sequence.


    #subseq(*args)    #make a new seq out of a subrange of current seq data.

    #reverse    #make a new seq that reverses the order of data.
    
    #close    # Close the seq.  This will also close/invalidate 
              #every child #position and derived sequence attached to 
              #this one.
    #closed?    # Is the seq closed?



  #nearbegin(len)  #is this seq within len elements of the beginning?
  #nearend(len)    #is this seq within len elements of the end?

    #more_data?   #is there any more data in the seq?    
    #was_data?    #has any data been seen so far, or are 
                  #we still at the beginning?

    
    #first    #return first element of data
    #last    #return last element of data



sequence classes:
base sequences:
Sequence      #ancestor class
  Indexed
    OfArray     #over data in an Array
    OfString    #over data in a String
  File          #over data in a File (no insert/delete)
  IO  (R/O)     #over data in an IO (pipe/socket/tty/whatever)
  Enum (R/O)    #over data in an Enumeration 
  SingleItem    #over a single scalar item
  OfHash         (**)
  OfObjectIvars  (**)
  OfObjectMethods  (**)

derived sequences:
  Shifting       #saves a copy of the base sequence data 
                 #(in another sequence) as it is read
  Buffered (**)  #makes unidirectional sequences bidirectional 
                 #(up to the buffer size)
  Reversed       #reverses the order of its base sequence
  Circular       #loops base sequence data over and over
  SubSeq         #extracts a contiguous subset of base sequence 
                 #data into a new seq
  List           #logically concatenates its base sequences
  Overlay (**)   #intercepts writes to the base seq
  Position       #an independant position within the base seq
  
Future:
  Scanning  (**)
  Splitting (**)
  Striding (**)
  Transforming (**)
  Branching (**)
  LinkedList (**)
  DoubleLinkedList (**)
  BinaryTree (**)

  Pipe        (**)       #a bidirectional communication channel 
                         #with sequence api
  IndexedList   (**)
  
 



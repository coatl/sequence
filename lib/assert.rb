# Copyright (C) 2006, 2011  Caleb Clausen
# Distributed under the terms of Ruby's license.

module Kernel
  def assert(expr,msg="assertion failed")
    defined? $Debug and $Debug and (expr or raise msg)
  end

  @@printed={}
  def fixme(s)
    unless @@printed[s] 
      @@printed[s]=1
      defined? $Debug and $Debug and $stderr.print "FIXME: #{s}\n"
    end
  end
end

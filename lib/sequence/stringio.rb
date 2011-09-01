require 'stringio'
class StringIO < Data
    # convert an StringIO to a seq
    def to_sequence
       Sequence::File.new(self)
    end
end


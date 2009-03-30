#eric's original test code; I can't say I understand it
BEGIN{exit}
# $Id$

require 'test/unit'
require 'sequence'
require 'sequence/usedeleteinsert'

# :stopdoc:

module Test
module Unit
    class TestSuite
        def run(result, &progress_block)
            yield(STARTED, name)
            if @tests.size>0 and @tests[0].class.respond_to?:random
                catch(:stop_suite) {
                    (@tests[0].class.random*@tests.size).to_i.times do
                        test = @tests[rand(@tests.size)]
                        catch(:invalid_test) {
                            test.run(result, &progress_block)
                        }
                    end
                }
            else
                @tests.each do |test|
                  test.run(result, &progress_block)
                end
            end
            yield(FINISHED, name)
        end
    end
end
end

ArgArray = Class.new(Array)

class Sequence
class Test < ::Test::Unit::TestCase
    def self.suite(random_iterations=8,random_seed=0,klass='',methods='',flags=0)
        return(::Test::Unit::TestSuite.new()) if !self.respond_to?:seed
        if !(@@output_level||=nil)
            @@output_level = ::Test::Unit::UI::SILENT
            ObjectSpace.each_object(::Test::Unit::AutoRunner) { |runner|
                @@output_level = runner.instance_eval { @output_level }
            }
        end
        if !(@@random_iterations||=nil)
            @@random_iterations = random_iterations.to_f
        end
        if !(@@random_seed||=nil)
            @@random_seed = random_seed.to_i.nonzero? || (srand;srand)
            puts("random_seed: #{@@random_seed}") if @@output_level>=::Test::Unit::UI::NORMAL
            srand(@@random_seed)
        end
        @klass = Regexp.new(klass)
        methods = Regexp.new(methods)
        @reject ||= nil
        public_instance_methods(true).each { |m|
            if matchdata = /^test_\d*(.*)/.match(m.to_s)
                undef_method(m) if @reject&&@reject=~matchdata[1] ||
                    !(methods=~matchdata[1])
            end
        }
        @flags = flags.to_i
        @use_positions = @flags[0].zero?
        @use_branches = true
        @allow_pruning = false
        self.plant
        super()
    end
    def self.plant
        before = sequence(0,1.5)
        after = sequence(0,1.5,before.class.new)
        seqs = seed(before,after)
        if @klass
            seqs.reject! { |seq| !(@klass===seq.class.to_s) }
        end
        return(self.plant) if seqs.empty?
        if @@output_level>=::Test::Unit::UI::NORMAL
            puts("\nnew(#{before.inspect}+#{after.inspect}) -> self")
        end
        @seqs_root = {
            :trunk => seqs,
            :positions => [],
            :branches => [],
        }
    end
    def self.element(offset=0,weight=1)
        elements[rand((weight*(elements.size+offset)).to_i)]
    end
    def self.sequence(offset=0,weight=2,value=empty)
        until (v = element(offset,weight)).nil?
            value << v
        end
        value
    end
    def self.random
        @@random_iterations
    end
    def self.reject(name,*args,&block)
        false
    end
    def setup
        seqs_tree = self.class.instance_eval{@seqs_root}
        level = 0
        @prune = proc{}
        while (branches = seqs_tree[:branches]).size.nonzero? and
                self.class.instance_eval{@use_branches}&&rand(3).zero?
            i = rand(branches.size)
            
            if _closed?(branches[i][:trunk])
                branches.slice!(i)
                break
            else
                @prune = proc { branches.slice!(i) }
                seqs_tree = branches[i]
                level += 1
            end
        end
        if (positions = seqs_tree[:positions]).size.nonzero? and
                self.class.instance_eval{@use_positions}&&rand(3).zero?
            i = rand(positions.size)
            if _closed?(positions[i])
                positions.slice!(i)
            else
                @prune = proc { positions.slice!(i) }
                seqs_tree = {
                    :trunk => positions[i],
                    :positions => seqs_tree[:positions],
                    :branches => seqs_tree[:branches],
                }
                level += 1
            end
        end
        @seqs_tree = seqs_tree
        @seqs = seqs_tree[:trunk]
        @positions = seqs_tree[:positions]
        @branches = seqs_tree[:branches]
        @level = level
        @state = ""
        @exec = nil
    end
    def teardown
        if not passed?
            if @@output_level>=::Test::Unit::UI::PROGRESS_ONLY
                puts("\n#{self}")
                puts("random_seed: #{@@random_seed}")
                puts(@call)
            end
            throw(:stop_suite)
        end
    end

    private
    def _closed?(seqs)
        ret0 = nil
        seqs.each_with_index { |seq,i|
            i==0 ? ret0 = seq.closed? : assert_equal(ret0,seq.closed?)
        }
        ret0
    end
    def _inspect_short(obj,_self=nil)
        if _self and _self.equal?(obj)
            "self"
        else
            obj.inspect.sub(/\A\#\<([\w\:]+?\:0x[\da-f]+).*\>\Z/,'#<\\1>')
        end
    end
    def _inspect_self(obj,_self=nil)
        if _self and _self.equal?(obj)
            "self"
        else
            obj.inspect
        end
    end
    def _inspect_merge(objects,selves=nil)
        _inspect_short(objects[0],selves&&selves[0])
    end
    def _multi_test(name,*args0,&assertion)
        block = args0.pop
        throw(:invalid_test) if self.class.reject(name,*args0,&block)
        seqs = @seqs
        call = @level.zero? ? "self." : "#{_inspect_merge(@seqs)}."
        call += "{" if @exec
        call += name.to_s
        args = args0.collect { |arg|
            ArgArray===arg ? _inspect_merge(arg) : _inspect_short(arg)
        }
        call += "(#{args.join(',')})" if not args.empty?
        call += " {#{block.inspect.sub(/\A\#<Proc\:0x[\da-f]+\@(.*?)\>\Z/,'\\1')}}" if block
        call += "}" if @exec
        @call = call
        print("\n#{call} ") if @@output_level==::Test::Unit::UI::NORMAL
        state = @state
        ret = ArgArray.new
        puts if @@output_level>=::Test::Unit::UI::VERBOSE
        @seqs.each_with_index do |seq,i|
            @state = state.clone
            initial = seq.inspect
            args = args0.collect { |arg|
                ArgArray===arg ? arg[i] :
                begin
                    arg.clone
                rescue TypeError
                    arg
                end
            }
            call = ""
            call += "{" if @exec
            call += name.to_s
            call += "(#{args.inspect[1..-2]})" if not args.empty?
            call += " #{block.inspect}" if block
            call += "}" if @exec
            if @@output_level>=::Test::Unit::UI::VERBOSE
                puts(initial)
                print("#{call} ")
            end
            @seq = seq
            if @exec
                ret << @exec.call(seq,name,*args,&block)
            else
                ret << seq.__send__(name,*args,&block)
            end
            message = [initial,call,seq.inspect].join("\n")
            puts("-> #{_inspect_self(ret[-1],seq)}") if @@output_level>=::Test::Unit::UI::VERBOSE
            #puts(seq.inspect) if @@output_level>=::Test::Unit::UI::VERBOSE
            assertion[i,ret[-1],seq,message]
        end
        @call += "-> #{_inspect_merge(ret,@seqs)}"
        print("-> #{_inspect_merge(ret,@seqs)}") if @@output_level==::Test::Unit::UI::NORMAL
        @prune[] if self.class.instance_eval{@allow_pruning}&&rand(2).zero?
        ret
    end
    def _test_equal(name,*args,&block)
        ret0 = nil
        _multi_test(name,*(args << block)) {
            |i,ret,seq,message|
            i==0 ? ret0 = ret : assert_equal(ret0,ret,message)
        }
    end
    def _test_matchdata(name,*args,&block)
        ret0 = nil
        _multi_test(name,*(args << block)) {
            |i,ret,seq,message|
            if i==0
                ret0 = ret
            elsif ret0.nil?
                assert_nil(ret)
            else
                assert_equal(ret0.to_a,ret.to_a)
            end
        }
    end
    def _test_match(name,*args,&block)
        ret0 = nil
        _multi_test(name,*(args << block)) {
            |i,ret,seq,message|
            if i==0
                ret0 = ret
            elsif ret0.nil?
                assert_nil(ret)
            else
                assert_equal(ret0[0,ret0.size-1],ret[0,ret.size-1])
            end
        }
    end
    def _exec_position?(seq,name,*args,&block)
        seq.position? { seq.__send__(name,*args,&block) }
    end
    def _test_position?(name,*args,&block)
        ret0 = nil
        @exec = method(:_exec_position?)
        _multi_test(name,*(args << block)) {
            |i,ret,seq,message|
            i==0 ? ret0 = ret : assert_equal(ret0,ret,message)
        }
    end
    def _test_self(name,*args,&block)
        ret0 = nil
        _multi_test(name,*(args << block)) {
            |i,ret,seq,message|
            ret0 = ret||nil if i==0
            assert_same(ret0&&seq,ret,message)
        }
    end
    def _test_position(name,*args,&block)
        new_seqs = ArgArray.new
        ret0 = nil
        _multi_test(name,*(args << block)) {
            |i,ret,seq,message|
            ret0 = ret if i==0
            if not ret0
                assert_nil(ret,message)
            else
                assert_not_nil(ret,message)
                new_seqs << ret
            end
        }
        @positions << new_seqs if ret0
    end
    def _test_branch(name,*args,&block)
        new_seqs = ArgArray.new
        ret0 = nil
        _multi_test(name,*(args << block)) {
            |i,ret,seq,message|
            ret0 = ret if i==0
            if not ret0
                assert_nil(ret,message)
            else
                assert_not_nil(ret,message)
                new_seqs << ret
            end
        }
        @branches << {
            :trunk => new_seqs,
            :positions => [],
            :branches => [],
        } if ret0
    end
    def _test_close(name,*args,&block)
        ret0 = nil
        _multi_test(name,*(args << block)) {
            |i,ret,seq,message|
            i==0 ? ret0 = ret : assert_equal(ret0,ret,message)
        }
        assert_same(true,_closed?(@seqs))
        if @level==0
            self.class.plant
        end
        ret0
    end
    
    
    def _opt(*args,&block)
        args = args[0,rand(args.size+1)]
        block and rand(2).zero? and args << block[]
        args
    end
    def _ornil(arg)
        rand(2).zero? ? arg : nil
    end
    # responds to ==element
    def _element
        self.class.element
    end                                  
    # responds to ==element
    def _scan_element
        self.class.element
    end
    # responds to [element]
    def _replacer
        lookup = {}
        self.class.elements.each { |e|
            lookup[e] = self.class.element(1)
        }
        lookup
    end
    # responds to <(int), abs (which responds to >(int))
    def _len
        rand(5)-2
    end
    # responds to if and the like (everything)
    def _boolean
        rand(2).zero?
    end
    def _booleannil
        case rand(3)
        when 0 then false
        when 1 then true
        when 2 then nil
        end
    end
    # responds to [int]
    def _read_sequence
        self.class.sequence(0,3)
    end
    # responds to <<element
    def _write_sequence
        self.class.sequence
    end
    # responds to [Integer] returning ==element responder
    def _scan_sequence
        self.class.sequence
    end
    # responds to [Integer] returning ==element responder
    def _scan_sequence
        self.class.sequence
    end
    # responds to [Integer] returning ==element responder
    def _each_sequence
        value = self.class.empty
        value << self.class.element
        while v = self.class.element(0,2)
            value << v
        end
        value
    end
    # responds to [int]
    def _read_pattern_sequence
        self.class.sequence(0,3,"")
    rescue TypeError
        throw(:invalid_test)
    end
    def _pattern(variable)
        n = 0
        seq1 = self.class.sequence(0,2,"")
        n = seq1.size
        seq1 = Regexp.escape(seq1)
        if n>=1 and rand(2).zero?
            seq1 = "[#{seq1}]"
            n = 1
        end
        alt1 = self.class.sequence(0,2,"")
        alt2 = self.class.sequence(0,2,"")
        n += alt1.size>alt2.size ? alt1.size : alt2.size
        alt1 = Regexp.escape(alt1)
        alt2 = Regexp.escape(alt2)
        if alt1.empty?
            if alt2.empty?
                seq2 = ""
            else
                seq2 = "(#{alt2})?"
            end
        else
            if alt2.empty?
                seq2 = "(#{alt1})?"
            else
                if alt1[0]==alt2[0]
                    seq2 = alt1
                else
                    seq2 = "(#{alt1}|#{alt2})"
                end
            end
        end
        if rand(2).zero?
            pat = seq1+seq2
        else
            pat = seq2+seq1
        end
        pat = "(?:#{pat})*" if variable
        pat = '\A'+pat if false==variable && rand(2).zero?
        pat = Regexp.new(pat)
        n += rand(2)
        n = -n if rand(2).zero?
        [pat,n]
    rescue TypeError
        throw(:invalid_test)
    end
    def _pos
        pos = rand(
            self.class.instance_eval{@seqs_root}[:trunk][0].size.abs.to_i+1
        )
        rand(2).zero? ? -(pos.nonzero?||0.0) : pos
    end
    def _prop_name
        rand(2).zero? ? :first : :last
    end
    def _prop_value
        rand(2).zero? ? "john" : "henry"
    end
    def _indexedwrite
        args = [_ornil(_pos)]
        args << _len if rand(2).zero?
        args << (args[1] ? _write_sequence : _element)
    end
    def _anyposition
        i = rand(@positions.size.nonzero?||throw(:invalid_test))
        @positions[i]
    end
    def _position
        i = rand(@positions.size.nonzero?||throw(:invalid_test))
        if _closed?(@positions[i])
            @positions.slice!(i)
            throw(:invalid_test)
        end
        @positions[i]
    end
    def _deleteposition
        i = rand(@positions.size.nonzero?||throw(:invalid_test))
        if _closed?(@positions[i])
            @positions.slice!(i)
            throw(:invalid_test)
        end
        @positions.slice!(i)
    end
    def _each_code
        proc { |v0| nil } # what to do?
    end
    def _each2_code
        proc { |v0| nil } # what to do?
    end
    def _collect_code
        lookup = {}
        elements = self.class.elements
        elements.each_with_index { |e,i|
            lookup[e] = elements[i+1]
        }
        proc { |v0| lookup[v0] }
    end
    def _collect2_code
        proc { |v0| v0.slice!(0);v0 }
    end
    def _position_code
        elements = self.class.elements
        proc {
            @seq.scan1next(elements[0]) ||
            @seq.position? { @seq.read1next==elements[1] }
        }
    end
    def _pos_code
        elements = self.class.elements
        proc {
            @seq.scan1next(elements[0]) ||
            @seq.position? { @seq.read1next==elements[1] }
        }
    end


    public
    define_method("test_delete1after?" ){_test_equal(:delete1after?)}
    define_method("test_delete1before?"){_test_equal(:delete1before?)}
    define_method("test_insert1before" ){_test_equal(:insert1before,_element)}
    define_method("test_insert1after"  ){_test_equal(:insert1after,_element)}
    define_method("test_read1next"     ){_test_equal(:read1next)}
    define_method("test_read1prev"     ){_test_equal(:read1prev)}
    define_method("test_write1next!"   ){_test_equal(:write1next!,_element)}
    define_method("test_write1prev!"   ){_test_equal(:write1prev!,_element)}
    define_method("test_write1next"    ){_test_equal(:write1next,_element)}
    define_method("test_write1prev"    ){_test_equal(:write1prev,_element)}
    define_method("test_skip1next"     ){_test_equal(:skip1next)}
    define_method("test_skip1prev"     ){_test_equal(:skip1prev)}
    define_method("test_delete1after"  ){_test_equal(:delete1after)}
    define_method("test_delete1before" ){_test_equal(:delete1before)}
    define_method("test_read1after"    ){_test_equal(:read1after)}
    define_method("test_read1before"   ){_test_equal(:read1before)}
    define_method("test_write1next?"   ){_test_equal(:write1next?,_element)}
    define_method("test_write1prev?"   ){_test_equal(:write1prev?,_element)}
    define_method("test_write1after!"  ){_test_equal(:write1after!,_element)}
    define_method("test_write1before!" ){_test_equal(:write1before!,_element)}
    define_method("test_write1after"   ){_test_equal(:write1after,_element)}
    define_method("test_write1before"  ){_test_equal(:write1before,_element)}
    define_method("test_skip1after"    ){_test_equal(:skip1after)}
    define_method("test_skip1before"   ){_test_equal(:skip1before)}
    define_method("test_write1after?"  ){_test_equal(:write1after?,_element)}
    define_method("test_write1before?" ){_test_equal(:write1before?,_element)}
    define_method("test_scan1next"     ){_test_equal(:scan1next,_scan_element)}
    define_method("test_scan1prev"     ){_test_equal(:scan1prev,_scan_element)}
    define_method("test_modify1next"   ){_test_equal(:modify1next,_replacer)}
    define_method("test_modify1prev"   ){_test_equal(:modify1prev,_replacer)}
    define_method("test_read"        ){_test_equal(:read,_len,*_opt(_booleannil,_read_sequence))}
    define_method("test_read!"       ){_test_equal(:read!,*_opt(_boolean,_booleannil,_read_sequence))}
    define_method("test_skip"        ){_test_equal(:skip,_len,*_opt(_booleannil))}
    define_method("test_skip!"       ){_test_equal(:skip!,*_opt(_boolean,_booleannil))}
    define_method("test_write"       ){_test_equal(:write,_write_sequence,*_opt(_boolean,_booleannil,_boolean))}
    define_method("test_write?"      ){_test_equal(:write?,_write_sequence,*_opt(_boolean,_boolean,_read_sequence))}
    define_method("test_scan"        ){_test_equal(:scan,_scan_sequence,*_opt(_boolean,_booleannil,_read_sequence))}
    define_method("test_scan_until"  ){_test_equal(:scan_until,_scan_sequence,*_opt(_boolean,_booleannil,_read_sequence))}
    define_method("test_1scan_pattern"){_test_equal(:scan_pattern,*(_pattern(false)+_opt(_boolean)))}
    define_method("test_2scan_pattern"){_test_matchdata(:scan_pattern,*(_pattern(false) << _boolean << _read_pattern_sequence))}
    define_method("test_1scan_pattern_until"){_test_equal(:scan_pattern_until,*(_pattern(nil)+_opt(_boolean)))}
    define_method("test_2scan_pattern_until"){_test_match(:scan_pattern_until,*(_pattern(nil)+[_boolean]+[_read_pattern_sequence]+_opt(rand(2))))}
    define_method("test_scan_pattern_while"){_test_equal(:scan_pattern_while,*(_pattern(true)+_opt(_boolean,_read_pattern_sequence,rand(2))))}
    define_method("test_1pos"        ){_test_equal(:pos,*_opt(_boolean))}
    define_method("test_2pos"        ){_test_equal(:pos,*_opt(_boolean),&_pos_code)}
    define_method("test_pos="        ){_test_equal(:pos=,_pos)}
    define_method("test_1pos?"       ){_test_equal(:pos?,_pos+rand(5)-2)}
    define_method("test_2pos?"       ){_test_equal(:pos?,*_opt(_boolean),&_pos_code)}
    define_method("test_to_i"        ){_test_equal(:to_i)}
    define_method("test_to_s"        ){_test_equal(:to_s)}
    define_method("test_prop"        ){_test_equal(:prop,_prop_name,*_opt(_prop_value))}
    define_method("test_closed?"     ){_test_equal(:closed?)}
    define_method("test_close"       ){_test_close(:close)}
    define_method("test_1position"   ){_test_position(:position,*_opt(_boolean))}
    define_method("test_2position"   ){_test_equal(:position,*_opt{_boolean},&_position_code)}
    define_method("test_position="   ){_test_equal(:position=,_position)}
    define_method("test_1position?"  ){_test_equal(:position?,_anyposition)}
    define_method("test_2position?"  ){_test_equal(:position?,*_opt{_boolean},&_position_code)}
    define_method("test_<=>"         ){_test_equal(:<=>,_position)}
    define_method("test_-"           ){_test_equal(:-,_position)}
    define_method("test_+"           ){_test_position(:+,_len)}
    define_method("test_succ"        ){_test_position(:succ)}
    define_method("test_pred"        ){_test_position(:pred)}
    define_method("test_begin"       ){_test_position(:begin)}
    define_method("test_end"         ){_test_position(:end)}
    define_method("test_size"        ){_test_equal(:size)}
    define_method("test_length"      ){_test_equal(:length)}
    define_method("test_empty?"      ){_test_equal(:empty?)}
    define_method("test_clear"       ){_test_equal(:clear)}
    define_method("test_replace"     ){_test_self(:replace,_write_sequence)}
    define_method("test_data"        ){_test_equal(:data)}
    define_method("test_<<"          ){_test_self(:<< ,_element)}
    define_method("test_>>"          ){_test_self(:>> ,_element)}
    define_method("test_slice"       ){_test_equal(:slice,*_opt(_ornil(_pos),_len))}
    define_method("test_[]"          ){_test_equal(:[],*_opt(_ornil(_pos),_len))}
    define_method("test_slice!"      ){_test_equal(:slice!,*_opt(_ornil(_pos),_len))}
    define_method("test_1[]="        ){_test_equal(:[]=,*(_opt(_pos) << _element))}
    define_method("test_2[]="        ){_test_equal(:[]=,_ornil(_pos),_len,_write_sequence)}
    define_method("test_1each"       ){_test_equal(:each,_ornil(_pos),_boolean,&_each_code)}
    define_method("test_2each"       ){_test_equal(:each,_ornil(_pos),_boolean,_each_sequence,&_each2_code)}
    define_method("test_1collect!"   ){_test_self(:collect!,_ornil(_pos),_boolean,&_collect_code)}
    define_method("test_2collect!"   ){_test_self(:collect!,_ornil(_pos),_boolean,_each_sequence,&_collect2_code)}
    define_method("test_1map!"       ){_test_self(:map!,_ornil(_pos),_boolean,&_collect_code)}
    define_method("test_2map!"       ){_test_self(:map!,_ornil(_pos),_boolean,_each_sequence,&_collect2_code)}
end
end

# :startdoc:


# Copyright (C) 2006,2008  Caleb Clausen
# Distributed under the terms of Ruby's license.
class Sequence
  class Circular < Sequence; end
  class List < Sequence
    def initialize(seqs)
      seqs.empty? and raise ArgumentError
      @list=seqs
      @current_idx=0
      @pos=0
      @start_pos=[0]
      
      @list=@list.inject([]){|li,seq|
        Circular===seq and raise 'no circular seqs in lists'
        Sequence===seq or raise ArgumentError
        if List===seq then li+seq.list else li<<seq end
      }
      @list.each{|seq| seq.on_change_notify(self) }
      _rebuild_idxs
      
      extend seqs.first.like
    end
 
    attr :list
    
    def change_notification(cu,first,oldsize,newsize)
      idx=@list.each_with_index{|item,i| cu.equal? item and break i}
      diff=newsize-oldsize
      (idx+1...@start_pos.size).each{|i|
        @start_pos[i]+=diff
      }
      @pos=_adjust_pos_on_change(@pos, first,oldsize,newsize)
      @current_idx=_lookup_idx @pos
      notify_change(self,@start_pos[idx]+first,oldsize,newsize)
    end
    
    def _rebuild_idxs(start=1)
      seed=@start_pos[0...start]
      seed.empty? and seed=[0]
      start==0 and start=1
      @start_pos=(start..@list.size).inject(seed){|arr,i| 
        arr<<arr.last+@list[i-1].size
      }
      #@start_pos.pop
      
      #maybe update @current_idx too?
    end
=begin    
    def _lookup_idx(pos)
      low=0;high=@start_pos.size-1
      while(high>low+1) 
        mid=(low+high)/2
        this_pos,next_pos=*@start_pos[mid,2]
        if pos<this_pos
          high=mid # - 1 ??
        elsif pos<next_pos
          return mid
        elsif pos==next_pos 
          return mid+1
        else
          low=mid + 1
        end
      end
      low
    end
=end
    def _lookup_idx(pos)
      pos==size and return @list.size-1
      assert((0...size)===pos)
      assert @start_pos.size==@list.size+1
      low=0;high=@start_pos.size-1
        assert @start_pos[low]<=pos
        assert @start_pos[high]>pos
      while(high>low+1)
        assert @start_pos[low]<=pos
        assert @start_pos[high]>pos
        mid=(low+high)/2
        case pos<=>@start_pos[mid]
        when -1; high=mid
        when  0; break low=mid
        when  1; low=mid
        end
      end
      assert @start_pos[low]<=pos
      assert @start_pos[low+1]>pos 
      low
    end
    
    def readahead(len)
      idx=_lookup_idx(pos)
      result=@list[idx][pos-@start_pos[idx],len] || new_data
      len-=result.size
      assert len>=0 
      i=nil
      (idx+1).upto(@list.size-1){|i| 
         break(result+=@list[i][0,len]) if len<@list[i].size          
         result+=@list[i].all_data
         len-=@list[i].size
      }
      result
    end
    
    def read(len)
      result=readahead(len)
      move result.size
      result
    end
    
    def holding
      oldpos,oldidx=@pos,@current_idx
      begin
        yield self
      ensure
        @pos,@current_idx=oldpos,oldidx
      end
    end

    #like #holding, but position is reset only if block returns false or nil (or
    #raises an exception).
    def holding?
      oldpos,oldidx=@pos,@current_idx
      begin
        result=yield self
      ensure
        (@pos,@current_idx=oldpos,oldidx) unless result
      end
    end

    #like #holding, but block is instance_eval'd in the seq.
    def holding! &block
      oldpos,oldidx=@pos,@current_idx
      begin
        instance_eval self, &block
      ensure
        @pos,@current_idx=oldpos,oldidx
      end
    end

    attr :pos
    
    def _pos=pos
      @pos=pos
      assert((0..size)===pos)
      @current_idx= _lookup_idx(pos)
    end
    
    def size
      @start_pos.last
    end
    
    def eof?
      @pos>=size
    end

    def + other
      return super unless ::Sequence===other
      return List[*@list+[other]]
    end
    
    def _fragment_discard_after(pos)
      idx=_lookup_idx(pos)
      pos-=@start_pos[idx]
      @list[idx]=@list[idx].subseq(0...pos)
      return idx
    end
    
    def _fragment_discard_before(pos)
      idx=_lookup_idx(pos)
      pos-=@start_pos[idx]
      @list[idx]=@list[idx].subseq(pos..-1)
      return idx
    end
    

    Overlaid =proc do
      class<<self
        def overlaid?; true end
        def subseq(*)
          result=super
          result.instance_eval(& Overlaid)
          return result
        end
      end
    end

    def modify(*args)
      result=repldata=args.pop
      
            
      repllen=repldata.size
#      unless repldata.empty?
        repldata=repldata.dup.to_sequence 

      
        #mark replacement data as overlaid
        repldata.instance_eval(&Overlaid)
#      end
      replseqs=[repldata]

      first,len,only1=_parse_slice_args(*args)
      if len.zero? and repllen.zero? 
        notify_change self,first,len,repllen
        return result
      end

      f_idx=first.zero?? 0 : _lookup_idx(first-1) 
      last_item_i=first+len-1
      last_item_i=0 if last_item_i<0
      l_idx=_lookup_idx(last_item_i)

      assert f_idx <= l_idx

      fragrest_f=first-@start_pos[i=_lookup_idx(first)]
      fragrest_l=first+len-@start_pos[l_idx]

      #@list[i] can be nil here... maybe because i==@list.size?
      assert fragrest_f <= @list[i].size
#      assert fragrest_l <= @list[l_idx].size unless l_idx == @list.size and fragrest_l.zero?

      #merge replacement data with adjacent seq(s) if also overlaid
      if fragrest_f.nonzero? #if inserted chunklet won't be empty
        replseqs.unshift( item=@list[i].subseq(0...fragrest_f) )
        if item.respond_to? :overlaid?
          repldata.prepend item.all_data
          replseqs.shift
        end
      end
         
      if  fragrest_l < @list[l_idx].size #if inserted chunklet won't be empty
        replseqs.push( item=@list[l_idx].subseq(fragrest_l..-1) )
        if item.respond_to? :overlaid?
          repldata.append item.all_data
          replseqs.pop
        end
      end

      
      replseqs.delete_if{|cu| !cu or cu.empty? }

      #now remove those elements in between and
      #insert replacement data at the same point
      assert f_idx >= 0
      assert l_idx >= 0
      assert f_idx < @list.size
      assert l_idx <= @list.size
      assert f_idx <= l_idx
      @list[i..l_idx]=replseqs
      #base=f_idx.zero?? 0 :  @start_idx[f_idx-1]
      #@start_idx[f_idx...l_idx]=[base+repldata.size]
      

      
      
      #rebuild indeces after altered part
      _rebuild_idxs(f_idx)
      @pos=_adjust_pos_on_change(@pos, first,len,result.size)
      @current_idx=_lookup_idx @pos

      notify_change(self,first,len,repllen)
      result
    end
    
   
    def append(data)
        if @list.last.overlaid?
          @list.last.append data
          return self
        end
        data=data.dup.to_sequence
        data.instance_eval(&Overlaid)
        @list<<data
        @start_pos<<@start_pos.last+data.size  
        notify_change(self,@start_pos[-2], 0, data.size)
        self
    end
    def prepend(data)
        if @list.first.overlaid?
          @list.first.prepend data
          return self
        end
        data=data.dup.to_sequence
        data.instance_eval(&Overlaid)
        @list[0,0]=data

        #insert data.size into beginning of @start_pos
        sz=data.size
        @start_pos=@start_pos.map{|n| n+sz} 
        @start_pos[0,0]=0
        
        notify_change(self,0, 0, data.size)
        self
    end
  end
  
#  class Indexed
#    def subseq(*args)
#      result=super
#      result and respond_to? :overlaid? and def result.overlaid?; true end
#      result
#    end
#  end
end

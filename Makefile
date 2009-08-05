.PHONY: all test docs gem tar pkg email
all: test

test:
	ruby -Ilib test/test_all.rb

docs:
	rdoc lib/*

pkg: gem tar

gem:
	gem build sequence.gemspec

tar:
	tar czf sequence-`ruby -r ./lib/sequence/version.rb -e 'puts Sequence::VERSION'`.tar.gz `git ls-files`

email: README.txt History.txt
	ruby -e ' \
  require "rubygems"; \
  load "./sequence.gemspec"; \
  spec= Gem::Specification.list.find{|x| x.name=="sequence"}; \
  puts "\
Subject: [ANN] Sequence #{spec.version} Released \
\n\nSequence version #{spec.version} has been released! \n\n\
#{Array(spec.homepage).map{|url| " * #{url}\n" }} \
 \n\
#{Sequence::Description} \
\n\nChanges:\n\n \
#{Sequence::Latest_changes} \
"\
'

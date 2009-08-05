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
  puts "Subject: [ANN] Sequence #{spec.version} Released"; \
  puts "\n"; \
  puts "Sequence version #{spec.version} has been released!"; \
  puts "\n"; \
  Array(spec.homepage).each{|url| puts " * #{url}" }; \
  puts "\n"; \
  puts Sequence::Description; \
  puts "\nChanges:\n"; \
  puts Sequence::Latest_changes; \
'

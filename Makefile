.PHONY: all test docs gem tar pkg email
all: test

test:
	ruby -Ilib test/test_all.rb

docs:
	rdoc lib/*

pkg: gem tar

gem:
	huh

tar:
	tar czf sequence-`ruby -r ./lib/sequence/version.rb -e 'puts Sequence::VERSION'`.tar.gz `git ls-files`

email: README.txt History.txt
	ruby -e ' \
  require "./lib/sequence/version.rb"; \
  pust "Subject: [ANN] Sequence #{Sequence::VERSION} Released
  puts "Sequence version #{Sequence::VERSION} has been released!"; \
  puts open("README.txt").read[/^==+ ?description.*?\n\n..*?\n\n/im]; \
  puts open("History.txt").read[/\A===.*?(?====)/m]; \
'

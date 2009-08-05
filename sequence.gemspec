# -*- encoding: utf-8 -*-

require './lib/sequence/version'
Sequence::Description=open("README.txt"){|f| f.read[/^==+ ?description[^\n]*?\n *\n?(.*?\n *\n.*?)\n *\n/im,1] }
Sequence::Latest_changes="###"+open("History.txt"){|f| f.read[/\A===(.*?)(?====)/m,1] }

Gem::Specification.new do |s|
  s.name = "sequence"
  s.version = Sequence::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Caleb Clausen"]
  s.date = Time.now.strftime("%Y-%m-%d")
  s.email = %q{caleb (at) inforadical (dot) net}
  s.extra_rdoc_files = ["README.txt", "COPYING", "GPL"]
  s.files = `git ls-files`.split
  s.has_rdoc = true
  s.homepage = %{http://github.com/coatl/sequence}
  s.rdoc_options = %w[--inline-source --main README.txt]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{sequence}
  s.rubygems_version = %q{1.3.0}
  s.test_files = %w[test/test_all.rb]
  s.summary = "A single api for reading and writing sequential data types."
  s.description = Sequence::Description

=begin
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mime-types>, [">= 1.15"])
      s.add_runtime_dependency(%q<diff-lcs>, [">= 1.1.2"])
    else
      s.add_dependency(%q<mime-types>, [">= 1.15"])
      s.add_dependency(%q<diff-lcs>, [">= 1.1.2"])
    end
  else
    s.add_dependency(%q<mime-types>, [">= 1.15"])
    s.add_dependency(%q<diff-lcs>, [">= 1.1.2"])
  end
=end
end

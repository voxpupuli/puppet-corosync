source 'https://rubygems.org'

group :development, :unit_tests do
  gem 'rake',                   :require => false
  gem 'rspec', '~>3.1.0',       :require => false
  gem 'rspec-puppet', '~>2.0',  :require => false
  gem 'puppetlabs_spec_helper', :require => false
  gem 'puppet-lint',            :require => false
  gem "puppet-blacksmith", "> 3.3.0", { "platforms" => ["ruby_19", "ruby_20", "ruby_21"] }
end

group :system_tests do
  gem 'beaker-rspec',           :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

# vim:ft=ruby

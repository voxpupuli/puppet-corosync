# frozen_string_literal: true
RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_configures, 'configures'
  c.expect_with :rspec do |r|
    r.syntax = :expect
  end
end

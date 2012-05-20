
require 'rhino'

require 'mocha'
require 'redjs'

module RedJS
  Context = Rhino::Context
  Error = Rhino::JSError
end

RSpec.configure do |config|
  config.filter_run_excluding :compat => /(0.5.0)|(0.6.0)/
end

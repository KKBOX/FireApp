require 'pathname'

$:.unshift Pathname(__FILE__).dirname.join('..', 'lib').to_s

require 'less'

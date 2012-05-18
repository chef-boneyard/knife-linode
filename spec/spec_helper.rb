require 'rspec'
require 'fog'

Fog.mock!

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib', 'chef', 'knife'))

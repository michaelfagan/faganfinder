require 'erubis'
require 'json'
require 'htmlcompressor'

engines = JSON.parse File.read('index.json'), object_class: OpenStruct

html = Erubis::Eruby.new(File.read 'index.erb.html').result(binding())

File.write 'temp/index.html', html

html = HtmlCompressor::Compressor.new(remove_intertag_spaces: true).compress html

File.write 'dist/index.html', html
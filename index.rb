require 'erubis'
require 'json'

engines = JSON.parse File.read('index.json'), object_class: OpenStruct

html = Erubis::Eruby.new(File.read 'index.erb.html').result(binding())

File.write 'dist/index.html', html
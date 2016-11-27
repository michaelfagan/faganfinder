require 'erubis'

html = Erubis::Eruby.new(File.read 'index.eruby').result(binding())

File.write 'dist/index.html', html
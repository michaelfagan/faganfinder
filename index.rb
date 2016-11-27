require 'erubis'
require 'json'
require 'htmlcompressor'
require 'html5_validator/validator'

# data for the template
engines = JSON.parse File.read('index.json'), object_class: OpenStruct

# generate html from the template
html = Erubis::Eruby.new(File.read 'index.erb.html').result(binding())

# output pretty html for readability
File.write 'temp/index.html', html

# validate the html
html_errors = Html5Validator::Validator.new.validate_text html
if html_errors.any?
  html_errors.map!{|e| "line #{e['lastLine']} #{e['message']}\n\t" + e['extract'].sub(/\n/, "\n\t") }
  html_errors.unshift 'HTML validation errors'
  STDERR.puts html_errors.join "\n\n"
  exit
end

# compress the html
html = HtmlCompressor::Compressor.new(remove_intertag_spaces: true).compress html

# all done, output html file
output_path  = 'dist/index.html'
File.write output_path, html
puts "HTML file saved to #{output_path}"
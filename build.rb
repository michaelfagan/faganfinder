require 'erubis'
require 'json'
require 'htmlcompressor'
require 'html5_validator/validator'
require 'sass'
require 'uglifier'

# compile css
begin
  css = Sass::Engine.new(File.read('index.scss.css'), syntax: :scss, style: :compressed).render.strip
rescue Exception => e
  STDERR.puts "SCSS error: #{e.message}"
  exit
end

# compile js
begin
  js = Uglifier.new.compile File.read('index.js')
rescue Exception => e
  STDERR.puts "JavaScript error: #{e.message}"
  exit
end


site_name = 'Fagan Finder'

Dir['./tools/*'].each do |file|

  page_id = /.*\/(.+)\.[^\.$]/.match(file)[1]
  puts page_id

  # other data for the template
  tool_groups = JSON.parse File.read(file), object_class: OpenStruct

  # generate html from the template
  html = Erubis::Eruby.new(File.read 'template.erb.html').result(binding())

  # validate the html
  html_errors = Html5Validator::Validator.new.validate_text html
  if html_errors.any?
    html_errors.map!{|e| "line #{e['lastLine']} #{e['message']}\n\t" + e['extract'].sub(/\n/, "\n\t") }
    html_errors.unshift "HTML validation errors - see #{html_path}"
    STDERR.puts html_errors.join "\n\n"
    exit
  end

  # compress the html
  html = HtmlCompressor::Compressor.new.compress html

  # all done, output html file
  output_path  = "dist/#{page_id}.html"
  File.write output_path, html
  puts "saved to #{output_path}"

end
require 'json'

class Page

  attr_reader :filepath, :id, :content, :number_of_tools, :external_links

  def self.filepath(id = '*', filetype = 'json')
    "./tools/#{id}.#{filetype}"
  end

  def filepath(filetype = 'json')
    self.class.filepath @id, filetype
  end

  def self.ids
    Dir[filepath]
      .sort_by(&File.method(:mtime)).reverse # most-recently-edited first
      .map{|f| /.*\/(.+)\.[^\.$]/.match(f)[1] }
  end

  def validate_json
    raise('path is absent or too short') if @json.path.length < 5
    raise('internal description is absent or too short') if @json.description.internal.length < 30
    raise('external description should be 100-160 characters') unless (100..160).include? @json.description.external.length
    raise('no tool groups') if @json.sections.length < 1
    @json.sections.each do |group|
      raise('group name is absent or too short') if !group.name || group.name.length < 4
      raise("no tools in group #{group.name}") if !group.tools || group.tools.length < 1
      group.tools.each do |tool|
        raise("tool name is absent or too short #{tool}") if !tool.name || tool.name.length < 3
        unless tool.searchUrl.include?('{q}') || tool.post
          raise "missing or bad searchUrl for #{tool.name}"
        end
        # note url validity is checked elsewhere
      end
    end
  end


  def initialize(id)
    @id = id
    @json = JSON.parse File.read(filepath), object_class: OpenStruct
  end

  def load

    validate_json

    # generate additional data from json
    @number_of_tools ||= @json.sections.map{|g| g.tools.length }.inject(:+)
    section_ids = []
    @json.sections.map! do |group|
      group.shortName ||= group.name
      group.id = group.shortName.gsub(/<[^>]+>/, '').gsub(/[^\w]+/, '_').gsub(/(^_)|(_$)/, '').downcase
      section_ids << group.id
      group
    end

    # load html
    @content =  File.read filepath('html')

    # extract links
    @external_links = []
    @json.sections.each do |group|
      @external_links.concat group.tools.map{|tool| tool.searchUrl.sub('{q}', 'test')}
    end
    # separate external links from links to other page sections
    urls_from_html = @content.scan(/ href="([^"]+)\"/).map{|m| m[0]}.partition{|u| u[0] == '#'}
    @external_links.concat urls_from_html[1].map{|u| u.gsub(/&amp;/, '&')}
    # validate internal links
    bad_internal_links = urls_from_html[0].reject{|u| section_ids.include? u.sub('#', '')}
    raise ('Bad link(s) within page: ' + bad_internal_links.join(', ')) if bad_internal_links.length > 0

  end

  def method_missing(method_name, *args, &block)
    @json.send method_name
  end

end
require 'json'

class Page

  attr_reader :groups, :id, :content, :number_of_tools, :external_links

  def self.path(id = '*', filetype = 'json')
    "./tools/#{id}.#{filetype}"
  end

  def path(filetype = 'json')
    self.class.path @id, filetype
  end

  def self.ids
    @@ids ||= Dir[path].map{|file| /.*\/(.+)\.[^\.$]/.match(file)[1] }
  end

  def validate_json
    raise('no tool groups') if @groups.length < 1
    @groups.each do |group|
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

    @groups = JSON.parse File.read(path), object_class: OpenStruct
    validate_json
    # generate additional data from json
    @number_of_tools ||= @groups.map{|g| g.tools.length }.inject(:+)
    section_ids = []
    @groups.map! do |group|
      group.shortName ||= group.name
      group.id = group.shortName.gsub(/<[^>]+>/, '').gsub(/[^\w]/, '_').downcase
      section_ids << group.id
      group
    end

    # load html
    @content =  File.read path('html')

    # extract links
    @external_links = []
    @groups.each do |group|
      @external_links.concat group.tools.map{|tool| tool.searchUrl.sub('{q}', 'test')}
    end
    # separate external links from links to other page sections
    urls_from_html = @content.scan(/ href="([^"]+)\"/).map{|m| m[0]}.partition{|u| u[0] == '#'}
    @external_links.concat urls_from_html[1].map{|u| u.gsub(/&amp;/, '&')}
    # validate internal links
    bad_internal_links = urls_from_html[0].reject{|u| section_ids.include? u.sub('#', '')}
    raise ('Bad link(s) within page: ' + bad_internal_links.join(', ')) if bad_internal_links.length > 0

  end

end
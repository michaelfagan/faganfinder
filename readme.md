# Fagan Finder

See http://www.faganfinder.com/


## Installation

1. Ruby
2. Git
3. Clone project
4. View final output in `dist/*.html`


# Make changes

1. `bundle install` (may prompt to install Aspell)
2. Change 
    * search tools in `tools/*.json`
    * content in `tools/*.html`
    * page template in `template.erb.html`
    * CSS in `index.scss.css`
    * JavaScript in `index.js`
3. `ruby build.rb`
4. fix any errors reported
    * any new (and existing links) that are detected to be possibly broken can be viewed on `test/bad_links.html` and tested manually
5. view final output as above
6. review diffs, commit, and push
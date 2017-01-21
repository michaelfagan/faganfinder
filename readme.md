# Fagan Finder

See http://www.faganfinder.com/


## Installation

1. Ruby
2. Git
3. Clone project
4. View final output in `dist/*.html`


# Make changes

1. `bundle install` (may prompt to install Aspell)
2. To make changes
    * search tools in `tools/*.json`
    * content in `tools/*.html`
    * page template in `index.erb.html`
    * CSS in `index.scss.css`
    * JavaScript in `index.js`
3. `ruby build.rb`
4. fix any errors reported and repeat step 3
    * any new (and existing) links that are found to be possibly broken can be viewed on `test/bad_links.html` and tested manually
    * any new valid words that are reported as misspelled can be added to the end of `test/allowed_words.txt` and it will be sorted when rebuilding
5. view final output as above
6. review diffs, commit, push
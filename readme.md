# Fagan Finder

See http://www.faganfinder.com/


## Installation

1. Ruby
2. Git
3. Clone project
4. View final output in `dist/*.html`


## Make changes

1. `bundle install`
2. `brew install aspell`
3. To make changes
    * search tools in `tools/*.json`
    * content in `tools/*.html`
    * page template in `index.erb.html`
    * CSS in `index.scss.css` and some inline in the HTML
    * JavaScript in `index.js`
4. `ruby build.rb`
5. fix any errors reported and repeat step 3
    * any new (and existing) links that are found to be possibly broken can be viewed on `test/bad_links.html` and tested manually
    * any new valid words that are reported as misspelled can be added to the end of `test/allowed_words.txt` and it will be sorted when rebuilding
6. view final output as above
7. review diffs, commit, push


## Understanding Google Analytics events
* Category: section name or `overview`, `header`, or `footer`
    * overview is for the first (untitled) details section
    * header and footer are for the 'About' link and the email link
* Action and label
    * `search`/`noquery-button`/`enter`
        * tool name
    * `detail-name`/`details`
       * i.e. clicking the section name (non-mobile) or 'Details' link (mobile)
    * `expand`/`collapse`
    * `link` or `in-page link`
        * link text, then link URL, separated by `||`
    * links to other pages on the site are not tracked via events
* for users without JavaScript, the tracking is different:
    * Category: `No JavaScript`
    * Action: `valid`/`invalid`
    * Label: the search URL template (roughly)

## Maintenance

### Check links
1. `irb`
2. `require './test/links.rb'`
3. `Link.check_all` (and wait...)
4. `exit`
5. `git diff test/links.json`
6. manually test links which were determined to be broken on `test/bad_links.html`

### Update dependencies
1. `bundle outdated`
2. `bundle update <gem>`
Ruby Crawler for Sitemaps
===========================

This simple crawler crawls a website and stores all 
internal linked urls in a sqlite database.
You can use this to create a google sitemap for example.


Instructions
==================

Please look in crawler.yml for configuration

Example crawler.yml file:

    config:
      standard_uri: http://www.yoursite.com/
      exclude_regex: \?*?(sort=|backlink=|SID=|.css)


How to create a sitemap with this crawler?

Make sure you have a configured crawler.yml and for 
google a sitemap_gen.py script with a configured 
config.xml with urllist support:
<urllist  path="urllist.txt"  encoding="UTF-8"  />)

Just take a coffee and run the following commands on your shell:

    ruby crawler.rb
    ruby crawler.rb urllist > urllist.txt # < this generates the urllist
    python sitemap_gen.py --config=config.xml

Now urllist sitemap should be generated and google 
notified about this update. Have fun!


License
=======

(The MIT License)

Copyright (c) 2008 Nico Puhlmann

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation the 
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
sell copies of the Software, and to permit persons to whom the Software 
is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
OR OTHER DEALINGS IN THE SOFTWARE.




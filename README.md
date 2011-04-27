Wall-Leecher
=== 

What
---
A command line wallpaper downloader written with Ruby's Event Machine that can download from a variety of sites.

Why
---
I got bored of manually searching for and downloading new wallpapers, so I wrote a script to automate the process. I use it to download a bunch of images to a folder, and then let the OS change every X mins.

Later I was experimenting with EM for batch IO processing, so  I thought I'll rewrite the script using all async IO. I thought it may be useful for other people so I added a few more sites, and packaged it up as a gem. 

How
---
` gem install wall-leecher`

Usage
---
wall-leecher SITE [options] [site-options]

Where SITE is one from (case insensitive):

* SkinsBe
* SimpleDesktops
* NationalGeographic
* Wallbase
* Write your own site scraper ( see the Development section below)

Disclaimer
---
PLEASE DO NOT UNNECESSARILY DOWNLOAD WALLPAPERS. I'm not responsible if you unintentionally create a Denial of Service attack by trying to download every image on a site. By default it will only download a dozen images, though this can be increased via a command line option.


Command line
---
This will give the options for a particular site
`wall-leech simpledesktops -h` 

`Options:`

`   -o, --output [DIR]               Directory to save the wallpapers. Default:/Users/<user>/Pictures/wallpaper/SimpleDesktop`

`    -v, --[no-]verbose               Run verbosely`

`    -d, --debug                      Run in debug mode`

`Common options:`

`    -h, --help                       Show this message`

`        --version                    Show version`

`Site options: SimpleDesktop`

`    -f, --first [N]                  First page to download from.	Default: 1`

`    -l, --last [N]                   Last page to download to	Default: 10`

`    -a, --[no-]all                   Download all. Overrides --last.	Default: false`


Internals
---
The abstract WallLeecher::Leecher class handles initialising the Event Machine loop, and each site specific leecher subclasses it. 

The WallLeecher::Fetcher class should be used by each site specific leecher for ALL IO to ensure not to block the reactor. It includes EM::Deferrable and neatly wraps em-http-request and em-files.  It is initialized with a URL and call backs can be set for geting a url or saving a url to a path. It also includes a scheduling check to ensure only N IOs are outstanding at any moment, ensuring the OS http stack is not over loaded.

The source is a good example on how to use Event Machine (or any other reactor framework) for batch processing. 

Develop
---

It 's easy to add additional sites as all the tricky event logic is provided. You just need to add your site specific scraper code (using Nokogiri / Mechanise / etc) that generates the list of urls to fetch. Wall-Leecher will do the dirty work of queuing the requests and writing to disk in a async EM compatible way.

To add your own site, first fork the project. Then Subclass WallLeecher::Leecher into the sites directory, and add your scraping logic. Use the WallLeecher::Fetcher class to do all IO once the reactor starts. Look at the lib/sites/simpledesktops.rb for a reference.

Your specific leecher can define command line options via self.site_params and receive them via @options.params.<option name>.

Outside downloading wallpapers, it would be relatively simple to make a general purpose high performance webcrawler. Your could scan a bunch of URLs (either given or dynamically generated by the crawler), and then process the results even saving to a SQL/ NoSQL DB. As long as all IO is evented is should be scaleable.

Contact me for any help or questions.

License
---
Copyright © 2011 Dharmesh Malam. All rights reserved.

ISC License

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
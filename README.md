 Wall-Leecher
=== 

What is it?
---
A command line wallpaper downloader written with Ruby's Event Machine that can download from a variety of sites.

Why?
---
I got bored of manually searching for and downloading new wallpapers, so I wrote a simple script to automate the process. I use it to download a few hundred images to a folder, and then let the OS change every X mins.

Later I thought it may be useful for other people so I rewrote it using Event Machine to be faster, added a few more sites, and packaged it up as a gem.

Install
---
` gem install wall-leech`

Usage
---
wall-leech SITE [options] [site-options]

Where SITE is one from (case insensitive):

* SkinsBe
* SimpleDesktops
* NationalGeographic
* Wallbase
* Write your own site scraper ( see Devel below)

PLEASE DO NOT UNNECESSARILY DOWNLOAD FROM SITES.
---

Command line
---
This will give the options for a particular site
`wall-leech simpledesktops ` 

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

`    -a, --[no-]all                   Download all. Overides --last.	Default: false`

Required Gems
---
* Eventmachine
* em-http-request --pre
* em-files --pre
* Nokogiri
* Ruby 1.9.2

OS
---
Should work on all platforms where gems and a compiler toolkit (for Eventmachine) is availiable.
Though only tested on Mac OSX 10.6 with Ruby 1.9.2

Internals
---
The Leecher class handles initialising the Event Machine loop, and each site specific leecher needs to subclass it. 

The Fetcher class should be used by each site specific leecher to do ALL IO to ensure not to block the reator. It includes EM::Deferrable and neatly wraps em-http-request and em-files.  It is initialized with a URL and call backs can be set for geting a url or saving a url to a path. It also includes a scheduling check to ensure only N IOs are outstanding at any moment, ensuring the OS http stack is not over loaded.

This project is also a good example on how to use Event Machine ( or any other reactor framework) for batch processing. 

Develop
---

It is very easy to add additional sites as all the tricky event logic is provided. You just need to add your site specific scraper code (using Nokogiri / Mechanise / etc) to generate the list of urls to save to disk. The project then does the dirty work of queuing the requests and writing to disk in a async EM compatible way.

To add your own site, first fork the project. Then Subclass Leecher in the sites directory, and add your scraping logic. Use the Fetcher class to do all IO once the reactor starts. Look at the simpledesktops.rb for a reference.

Your specific leecher can define command line options via self.site_params and receive them via @options.params.<option name>.

Outside downloading wallpapers, it would be very easy to turn this into a general purpose high performance webcrawler. Your could scan a bunch of URLs (either given or dynamically generated by the crawler), and then process the results even saving to a SQL/ NoSQL DB. As long as all IO is evented is should be relatively easy to scale.

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

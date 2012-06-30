# Pullcrusher

There are lots of great utilities out there to losslessly optimize
images, but most people forget to run them.  Pullcrusher makes it easy
to optimize the images of any GitHub repository, and contribute the
optimizations back to the maintainer as a pull request.

We stand on the shoulders of giants!  Thanks to: image_optim, ruby-git, methadone
and octokit.

[![Build Status](https://secure.travis-ci.org/mroth/pullcrusher.png?branch=master)](http://travis-ci.org/mroth/pullcrusher)
[![Dependency Status](https://gemnasium.com/mroth/pullcrusher.png)](https://gemnasium.com/mroth/pullcrusher)

## Prerequisites

Get dependencies for image optimization, on MacOSX:

    brew install advancecomp gifsicle jpegoptim jpeg optipng pngcrush

Debian/Ubuntu:

    sudo apt-get install -y advancecomp gifsicle jpegoptim libjpeg-progs optipng pngcrush

## Installation

Install it via:

    $ gem install pullcrusher

On some setups (default MacOSX) that may need a `sudo` first.

## Usage

Simply do a `pullcrush [repo_name]` using the github style short-name
for a repository, e.g. `mroth/pullcrusher`.

Pullcrusher will locate all images, compress them, and then ask you if
you want it to automatically fork on github and submit a pull request.
Simply type "Y" if you like and you are done!

### Sample output

    % pullcrush waferbaby/usesthis
    *** Asking Github to find us the URI for waferbaby/usesthis
    *** Cloning git@github.com:waferbaby/usesthis.git to local filesystem
    *** Finding and processing any candidate files
        public/images/interviews/chris.ilias.knives.jpg
            34415 -> 34204 (211 saved)
        public/images/interviews/chris.ilias.spoons.jpg
            40466 -> 40126 (340 saved)
        public/images/interviews/julian.bleecker.cameras.jpg
            135909 -> 133247 (2662 saved)
        public/images/interviews/khoi.vinh.home.jpg

[snip]

        public/images/portraits/zed.shaw.jpg
            143185 -> 141055 (2130 saved)
    *** 286 files processed, 136 successfully optimized for total savings of 400438 bytes.
    Do you want to automatically fork and pull request? [y/N] y
    *** Git branching and commiting all changed files
    *** Forking the original repo on github
    *** Pushing changes to your forked copy of the repo
    *** Creating a pull request...
    *** Done! Pull request is at https://github.com/waferbaby/usesthis/pull/5

## SSH setup and caveats

### SSH
We use standard git ssh to push changes to your github account.  You'll
want to make sure you have [SSH keys properly setup](https://help.github.com/articles/generating-ssh-keys). 

(Does anyone actually prefer HTTPS with credential caching as github thinks?  lmk if
this is something we need to add to pullcrusher).

### GitHub Credentials
The first time you run pullcrusher, it will ask for your GitHub username
and password to obtain a oAuth token (or possibly just your password, if 
it can locate your Github username in your git configuration).  This is 
totally cool and awesome, but if you don't want that token on your hard 
drive for any reason, its located at `~/.config/pullcrusher.yml`.

We use this so we can use the Github API to handle forking
repositories.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

I'm trying to learn more about using tests so bonus points if you
include a test for your new functionality or fix. (Or, if you just want
to write some tests for existing functionality, that's awesome too!)

## TODO
Things that still need to be done before v0.0.1 of this gem gets
released.

  * Minimal error handling (somewhat taken care of since Methadone handles exceptions okay) √
  * Handle your own repos not just others (cant do a pull request
    really? I guess just leave it in branch and ask person to do
    manually?) (PUNTING ON THIS TILL NEXT VERSION)
  * Some very very basic tests, and setup travis-ci to ensure we run on
    ruby 1.8.7 as well. √


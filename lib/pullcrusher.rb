# NOTE: This was one of the first things I ever wrote in Ruby, & I was a _much_
# poorer programmer back then!  A pull request to clean it up and modernize it
# would very welcome, but I've moved on to other projects and it isn't worth it
# for me to do it myself since it currently performs its function.
#
# Good luck.
#
# xoxo,
# -mroth

require "pullcrusher/version"
require "auth/github"

require "git"
require "image_optim"
require "octokit"
require "virtus"
require "methadone"

module Pullcrusher

  class Pullcrusher
    include Methadone::CLILogging

    attr_accessor :ok_client, :github_username

    # Class constructor
    #
    # authclient - An initialized Octokit client with authorization.
    # If none is provided, a public client will be used (which cannot perform many actions)
    #
    def initialize(authclient=nil)
      unless authclient.nil?
        @ok_client = authclient
        @github_username = authclient.login
      else
        @ok_client = Octokit::Client.new
      end
    end

    class Results
      include Virtus
      attribute :bytes_before, Integer
      attribute :bytes_saved, Integer
      attribute :filez_candidates, Integer
      attribute :filez_optimized, Integer
    end

    # Looks up a github style "username/repo" repository name
    #
    # repo_name - the github style repository name
    #
    # Returns a octokit repo object
    def repo_from_shortname(repo_name)
      @ok_client.repo(repo_name)
    end

    # Clones a remote git repository to the local filesystem
    #
    # uri - the URI of the remote git repository
    #
    # Returns a Git object representing the repository in the local filesystem.
    def clone_repo(repo_name)
      FileUtils.mkdir_p('/tmp/pullcrusher')
      dirname = repo_name.gsub('/','-')
      target = "/tmp/pullcrusher/#{dirname}"
      uri = repo_from_shortname(repo_name).clone_url

      #check if tmp directory already exists, if so, clobber it
      FileUtils.remove_dir(target) if File.directory?(target)

      g = Git.clone(uri,target)
    end

    # Given a directory, identify any files that are possible candidates for optimization.
    # This is naive, and only looks based on filename for now.
    #
    # dir - the directory to recursively search for candidate files
    #
    # Returns an array of file paths.
    def get_candidate_files(dir)
      Dir.chdir(dir)
      Dir.glob("**/*.{jpg,png,gif}")
    end

    # Convenience method to take a repo by string name, and do all the processing.
    #
    # repo_name - the github style repository name
    #
    # Returns an array containing both a Results hash, and the fs_repo reference that was cloned
    def process_repo(repo_name)
      info "*** Asking GitHub to find us the URI for #{repo_name}"
      orig_repo = repo_from_shortname(repo_name)

      info "*** Cloning #{orig_repo.ssh_url} to local filesystem"
      fs_repo = clone_repo(repo_name)

      info "*** Finding and processing any candidate files"
      results = process_files_from_repo( fs_repo )

      info "*** #{results.filez_candidates} files processed, #{results.filez_optimized} successfully optimized for total savings of #{results.bytes_saved} bytes."
      return results, fs_repo
    end


    # Convenience method to take a Git repository object, identify and process
    #
    # fs_repo - ruby-git object for the repo on filesystem
    #
    # Returns a Results object
    def process_files_from_repo(fs_repo)
      process_files( get_candidate_files(fs_repo.dir.to_s) )
    end

    # Given a list of files, process with image_optim to optimized file size.
    # Files are modified in place in file system.
    #
    # filez - the list of filez to process
    #
    # Returns a Results object with number of files optimized and bytes saved.
    def process_files(filez)
      #TODO: reject any files larger than MAXSIZE
      # perhaps use Enumerable reject for this!

      #
      # create an ImageOptim instance
      #
      io = ImageOptim.new(:pngout => false) #, :threads => THREADS)

      filez_optimized = 0
      bytes_saved = 0
      bytes_total = 0

      io.optimize_images!(filez) do |path,optimized|
        if optimized
          filez_optimized += 1
          size_after = File.size(path)
          size_before = optimized.original_size
          size_diff = size_before - size_after
          bytes_total += size_before
          bytes_saved += size_diff
          info "\t#{path}\n\t\t#{size_before} -> #{size_after} (#{size_diff} saved)"
        else
          info "\t#{path}"
        end
      end

      Results.new(:bytes_saved => bytes_saved, :filez_optimized => filez_optimized, :filez_candidates => filez.count)
    end

    # Fork and pull baby!
    #
    # fs_repo - git handle to the filesystem repo
    # repo_name - github style name as a string
    # results - a Pullcrusher::Results object from the optimization
    #
    # Returns nothing?
    def fork_and_pull(fs_repo, repo_name, results)
      #DONE: commit changed files
      info "*** Git branching and commiting all changed files"
      fs_repo.branch('pullcrushed').checkout
      fs_repo.add('.')
      fs_repo.commit('Optimized image files via pullcrusher')

      #DONE: fork original repo (via octokit)
      info "*** Forking the original repo on github"
      fork = @ok_client.fork(repo_name)

      #DONE: add forked repo as a new remote to git repo (or just change default?)
      fs_repo.add_remote('myfork', fork.ssh_url)

      #DONE: push new commits to GH remote
      info "*** Pushing changes to your forked copy of the repo"
      fs_repo.push( fs_repo.remote('myfork'), 'pullcrushed' )

      info "*** Creating a pull request..."
      #def create_pull_request(repo, base, head, title, body, options={})
      pr = @ok_client.create_pull_request(
        repo_name,
        "master", #BASE
        "#{@github_username}:pullcrushed", #HEAD
        "Optimized image files via pullcrusher",
        "Hi there!  I've used [pullcrusher](http://github.com/mroth/pullcrusher) to optimize images for this this repository losslessly.\n\n
        #{results.filez_optimized} files were optimized for a total savings of #{results.bytes_saved} bytes."
      )
      info "*** Done! Pull request is at #{pr.html_url}"
    end

  end

end

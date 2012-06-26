require "pullcrusher/version"
require "auth/github"

require "git"
require "image_optim"
require "octokit"
require "virtus"

require "pry"

module Pullcrusher
class Pullcrusher

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
        attribute :bytes_saved, Integer
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
        puts "*** Asking Github to find us the URI for #{repo_name}"
        orig_repo = repo_from_shortname(repo_name)

        puts "*** Cloning #{orig_repo.ssh_url} to local FS"
        fs_repo = clone_repo(repo_name)

        puts "*** Finding and processing any candidate files"
        results = process_files_from_repo( fs_repo )

        #if (results.filez_optimized < 1)
        #    puts "--- All done, nothing was optimized!"
        #    return results #we're done, drop out of method
        #end

        #puts "-"*80
        puts "*** #{results.filez_optimized} files were optimized for a total savings of #{results.bytes_saved} bytes."
        return results, fs_repo
    end


    # Convenience method to take a Git repository object, identify and process
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

        filez.each do |f|
            size_before =  File.size(f)
            puts "\t#{f}"
            if (io.optimize_image!(f)) #returns true when an optimization has been made
                filez_optimized += 1
                size_after = File.size(f)
                size_diff = size_before - size_after
                bytes_saved += size_diff
                puts "\t\t#{size_before} -> #{size_after} (#{size_diff} saved)"
            end
        end

        #puts "\tOptimized #{filez_optimized} files for a total savings of #{bytes_saved} bytes"
        Results.new(:bytes_saved => bytes_saved, :filez_optimized => filez_optimized)
    end

    # Fork and pull baby!
    #
    # fs_repo - git handle to the filesystem repo
    # repo_name - github style name as a string
    # results - a Pullcrusher::Results object from the optimization
    #
    # Returns nothing?
    def fork_and_pull(fs_repo, repo_name, results)
        #TODO: set name and email for git commits?!
        #nope handle this in bot insteat
        #fs_repo.config('user.name', 'PullCrusher Bot')
        #fs_repo.config('user.email','mrothenberg+pullcrusher@gmail.com')
        #fs_repo.config('credential.git@github.com.username', 'PullcrusherBot')

        
        #DONE: commit changed files
        puts "*** Git branching and commiting all changed files"
        fs_repo.branch('pullcrushed').checkout
        fs_repo.add('.')
        fs_repo.commit('Optimized image files via pullcrusher')

        #DONE: fork original repo (via octokit)
        puts "*** Forking the original repo on github"
        fork = @ok_client.fork(repo_name)

        #DONE: add forked repo as a new remote to git repo (or just change default?)
        fs_repo.add_remote('myfork', fork.ssh_url)

        #DONE: push new commits to GH remote
        puts "*** Pushing changes to your forked copy of the repo"
        fs_repo.push( fs_repo.remote('myfork'), 'pullcrushed' )

        puts "*** Creating a pull request..."
        #def create_pull_request(repo, base, head, title, body, options={})
        pr = @ok_client.create_pull_request(
            repo_name,
            "master", #BASE
            "#{@github_username}:pullcrushed", #HEAD
            "Optimized image files via pullcrusher",
            "Hi there!  I've used [pullcrusher](http://github.com/mroth/pullcrusher) to optimize images for this this repository losslessly.\n\n
            #{results.filez_optimized} files were optimized for a total savings of #{results.bytes_saved} bytes."
        )
        puts "*** Done! Pull request is at #{pr.html_url}"
    end
end
end


require "pullcrusher/version"

require "git"
require "image_optim"
require "octokit"
require "virtus"

class Pullcrusher

    attr_accessor :ok_client, :github_username

    # Class constructor
    #
    # github_username - github username as a string
    # github_password - github password as a string
    #
    def initialize(github_username, github_password)
        @github_username = github_username
        #@github_password = github_password
        @ok_client = Octokit::Client.new(:login => github_username, :password => github_password)
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
        g = Git.clone(uri,target)
        #g.dir.to_s
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

    def fork_and_pull()
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
        fork = ok_client.fork(repo_name)

        #DONE: add forked repo as a new remote to git repo (or just change default?)
        fs_repo.add_remote('myfork', fork.ssh_url)

        #DONE: push new commits to GH remote
        puts "*** Pushing changes to your forked copy of the repo"
        fs_repo.push( fs_repo.remote('myfork'), 'pullcrushed' )

        puts "*** Creating a pull request..."
        #def create_pull_request(repo, base, head, title, body, options={})
        pr = ok_client.create_pull_request(
            repo_name,
            "master", #BASE
            "#{$username}:pullcrushed", #HEAD
            "Optimized image files via pullcrusher",
            "Hi there!  I've used [pullcrusher](http://github.com/mroth/pullcrusher) to optimize images for this this repository losslessly.\n\n
            #{results.filez_optimized} files were optimized for a total savings of #{results.bytes_saved} bytes."
        )
        puts "*** Done! Pull request is at #{pr.html_url}"
    end
end



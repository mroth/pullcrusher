#
# stating point for this was this gist: https://gist.github.com/2771702
#
require 'octokit'
require 'yaml'
require 'highline/import'

class GitHubAuth
  # Change NOTE, SCOPES and CREDENTIALS to match your app's needs.
  NOTE = "Pullcrusher!"
  SCOPES = ["user","repo"]
  CREDENTIALS = File.join("#{ENV['HOME']}", ".config", "pullcrusher.yml")

  def self.client
    new.client
  end

  def client
    @client ||= lambda do
      unless File.exist?(CREDENTIALS)
        authenticate
      end
      Octokit::Client.new(YAML.load_file(CREDENTIALS))
    end.call
  end

  private
  def authenticate
    login = password = token = ""
    login = `git config github.user`.chomp
    login = ask_login if login.empty?
    password = ask_password
    auth_client = Octokit::Client.new(:login => login, :password => password)
    auth = auth_client.authorizations.detect { |a| a.note == NOTE }
    unless auth
      auth = auth_client.create_authorization(:scopes => SCOPES, :note => NOTE)
    end
    File.open(CREDENTIALS, 'w') do |f|
      f.puts({ :login => login, :access_token => auth.token }.to_yaml)
    end
  end

  def ask_login
    ask("Enter you GitHub username: ")
  end

  def ask_password
    ask("Enter your GitHub password (this will NOT be stored): ") { |q| q.echo = '*' }
  end

end

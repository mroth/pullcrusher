require 'test/unit'
require 'pullcrusher'

class TestPullcrusherGithubIntegration < Test::Unit::TestCase

	def test_github_lookup
		pc = Pullcrusher::Pullcrusher.new #unauthed client

		assert_equal pc.repo_from_shortname('mroth/pullcrusher').clone_url, 'https://github.com/mroth/pullcrusher.git'
	end

end
require 'test/unit'
require 'pullcrusher'

class TestPullcrusher < Test::Unit::TestCase
	def test_github_integration
		pc = Pullcrusher::Pullcrusher.new #unauthed client

		assert_equal pc.repo_from_shortname('mroth/pullcrusher').clone_url, 'https://github.com/mroth/pullcrusher.git'
	end
end
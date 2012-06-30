require 'test/unit'
require 'pullcrusher'

class TestPullcrusherGitIntegration < Test::Unit::TestCase

	def test_can_clone_repo
		pc = Pullcrusher::Pullcrusher.new

		assert_nothing_raised do
			pc.clone_repo('PullcrusherBot/pullcrusher_test_repo')
		end
		assert File.directory?("/tmp/pullcrusher/PullcrusherBot-pullcrusher_test_repo/.git"), "Cloned repo exists on filesystem"
	end

end
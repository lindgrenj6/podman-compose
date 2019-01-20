require 'minitest/autorun'
require 'podman-compose'

class PodmanComposeTest < Minitest::Test
  def test_output
    assert_equal("hello!",Podman::Compose.hi)
  end
end

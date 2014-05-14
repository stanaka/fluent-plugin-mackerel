require 'helper'

class MackerelOutputTest < Test::Unit::TestCase

  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    type mackerel
    api_key 123456
    hostid xyz
    metrics_prefix service
    out_keys val1,val2,val3
  ]

  CONFIG_NOHOST = %[
    type mackerel
    api_key 123456
    metrics_prefix service
    out_keys val1,val2,val3
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::MackerelOutput, tag).configure(conf)
  end

  def test_configure

    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }

    assert_raise(Fluent::ConfigError) {
      d = create_driver(CONFIG_NOHOST)
    }

    d = create_driver()
    assert_equal d.instance.instance_variable_get(:@api_key), '123456'
    assert_equal d.instance.instance_variable_get(:@hostid), 'xyz'
    assert_equal d.instance.instance_variable_get(:@metrics_prefix), 'service'
    assert_equal d.instance.instance_variable_get(:@out_keys), ['val1','val2','val3']
  end

  def test_write
    d = create_driver()
    stub(d.instance.mackerel).post_metrics([
      {"hostId"=>"xyz", "value"=>1.0, "time"=>1399997498, "name"=>"service.val1"},
      {"hostId"=>"xyz", "value"=>2.0, "time"=>1399997498, "name"=>"service.val2"},
      {"hostId"=>"xyz", "value"=>3.0, "time"=>1399997498, "name"=>"service.val3"},
      {"hostId"=>"xyz", "value"=>5.0, "time"=>1399997498, "name"=>"service.val1"},
      {"hostId"=>"xyz", "value"=>6.0, "time"=>1399997498, "name"=>"service.val2"},
      {"hostId"=>"xyz", "value"=>7.0, "time"=>1399997498, "name"=>"service.val3"},
    ])

    ENV["TZ"]="Asia/Tokyo"
    t = Time.strptime('2014-05-14 01:11:38', '%Y-%m-%d %T')
    d.emit({'val1' => 1, 'val2' => 2, 'val3' => 3, 'val4' => 4}, t)
    d.emit({'val1' => 5, 'val2' => 6, 'val3' => 7, 'val4' => 8}, t)
    d.run()
  end


end
require "minitest_helper"

class TestToJson < Minitest::Test
  class Subject < ToJson::Serializer
    def serialize(controller, station, timestamps, media_type_scope: :default)
      put :controller, controller
      put :station, station
      put :timestamps, timestamps
      put :media_type_scope, media_type_scope
    end
  end

  def test_that_it_has_a_version_number
    refute_nil ::ToJson::VERSION
  end

  def test_instance_method_will_return_json
    assert_equal Subject.new.json!(:controller, :station, [:timestamps], media_type_scope: :media_files),
      '{"controller":"controller","station":"station","timestamps":["timestamps"],"media_type_scope":"media_files"}' + "\n"
  end

  def test_class_method_will_return_json
    assert_equal Subject.json!(:controller, :station, [:timestamps], media_type_scope: :media_files),
      '{"controller":"controller","station":"station","timestamps":["timestamps"],"media_type_scope":"media_files"}' + "\n"
  end
end

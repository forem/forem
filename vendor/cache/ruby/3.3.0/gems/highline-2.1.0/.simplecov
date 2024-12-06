unless SimpleCov.running
  SimpleCov.start do
    add_filter "test_"
  end
end

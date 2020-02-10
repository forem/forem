TestProf::LetItBe.configure do |config|
  config.register_modifier :readonly do |record, val|
    next record unless record.is_a?(::ActiveRecord::Base)

    next record unless val

    record.tap(&:readonly!)
  end

  config.alias_to :let_it_be_readonly, readonly: true
  config.alias_to :let_it_be_changeable, reload: true
end

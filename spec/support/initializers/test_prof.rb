# see <https://test-prof.evilmartians.io/#/let_it_be>
TestProf::LetItBe.configure do |config|
  config.register_modifier :readonly do |record, val|
    next record unless record.is_a?(::ActiveRecord::Base)

    next record unless val

    record.tap(&:readonly!)
  end

  # marks the record as readonly
  config.alias_to :let_it_be_readonly, readonly: true

  # reloads the record from the DB, with `record.reload`
  config.alias_to :let_it_be_changeable, reload: true

  # creates a new instance of the same record in memory
  config.alias_to :let_it_be_refindable, refind: true
end

# frozen_string_literal: true

Capybara::SpecHelper.spec '#has_table?' do
  before do
    @session.visit('/tables')
  end

  it 'should be true if the table is on the page' do
    expect(@session).to have_table('Villain')
    expect(@session).to have_table('villain_table')
    expect(@session).to have_table(:villain_table)
  end

  it 'should accept rows with column header hashes' do
    expect(@session).to have_table('Horizontal Headers', with_rows:
      [
        { 'First Name' => 'Vern', 'Last Name' => 'Konopelski', 'City' => 'Everette' },
        { 'First Name' => 'Palmer', 'Last Name' => 'Sawayn', 'City' => 'West Trinidad' }
      ])
  end

  it 'should accept rows with partial column header hashses' do
    expect(@session).to have_table('Horizontal Headers', with_rows:
      [
        { 'First Name' => 'Thomas' },
        { 'Last Name' => 'Sawayn', 'City' => 'West Trinidad' }
      ])
  end

  it 'should accept rows with array of cell values' do
    expect(@session).to have_table('Horizontal Headers', with_rows:
      [
        %w[Thomas Walpole Oceanside],
        ['Ratke', 'Lawrence', 'East Sorayashire']
      ])
  end

  it 'should consider order of cells in each row' do
    expect(@session).not_to have_table('Horizontal Headers', with_rows:
      [
        %w[Thomas Walpole Oceanside],
        ['Lawrence', 'Ratke', 'East Sorayashire']
      ])
  end

  it 'should accept all rows with array of cell values' do
    expect(@session).to have_table('Horizontal Headers', rows:
      [
        %w[Thomas Walpole Oceanside],
        %w[Danilo Wilkinson Johnsonville],
        %w[Vern Konopelski Everette],
        ['Ratke', 'Lawrence', 'East Sorayashire'],
        ['Palmer', 'Sawayn', 'West Trinidad']
      ])
  end

  it 'should match with vertical headers' do
    expect(@session).to have_table('Vertical Headers', with_cols:
      [
        { 'First Name' => 'Thomas' },
        { 'First Name' => 'Danilo', 'Last Name' => 'Wilkinson', 'City' => 'Johnsonville' },
        { 'Last Name' => 'Sawayn', 'City' => 'West Trinidad' }
      ])
  end

  it 'should match col with array of cell values' do
    expect(@session).to have_table('Vertical Headers', with_cols:
      [
        %w[Vern Konopelski Everette]
      ])
  end

  it 'should match cols with array of cell values' do
    expect(@session).to have_table('Vertical Headers', with_cols:
      [
        %w[Danilo Wilkinson Johnsonville],
        %w[Vern Konopelski Everette]
      ])
  end

  it 'should match all cols with array of cell values' do
    expect(@session).to have_table('Vertical Headers', cols:
      [
        %w[Thomas Walpole Oceanside],
        %w[Danilo Wilkinson Johnsonville],
        %w[Vern Konopelski Everette],
        ['Ratke', 'Lawrence', 'East Sorayashire'],
        ['Palmer', 'Sawayn', 'West Trinidad']
      ])
  end

  it "should not match if the order of cell values doesn't match" do
    expect(@session).not_to have_table('Vertical Headers', with_cols:
      [
        %w[Vern Everette Konopelski]
      ])
  end

  it "should not match with vertical headers if the columns don't match" do
    expect(@session).not_to have_table('Vertical Headers', with_cols:
      [
        { 'First Name' => 'Thomas' },
        { 'First Name' => 'Danilo', 'Last Name' => 'Walpole', 'City' => 'Johnsonville' },
        { 'Last Name' => 'Sawayn', 'City' => 'West Trinidad' }
      ])
  end

  it 'should be false if the table is not on the page' do
    expect(@session).not_to have_table('Monkey')
  end

  it 'should find row by header and cell values' do
    expect(@session.find(:table, 'Horizontal Headers')).to have_selector(:table_row, 'First Name' => 'Thomas', 'Last Name' => 'Walpole')
    expect(@session.find(:table, 'Horizontal Headers')).to have_selector(:table_row, 'Last Name' => 'Walpole')
    expect(@session.find(:table, 'Horizontal Headers')).not_to have_selector(:table_row, 'First Name' => 'Walpole')
  end

  it 'should find row by cell values' do
    expect(@session.find(:table, 'Horizontal Headers')).to have_selector(:table_row, %w[Thomas Walpole])
    expect(@session.find(:table, 'Horizontal Headers')).not_to have_selector(:table_row, %w[Walpole Thomas])
    expect(@session.find(:table, 'Horizontal Headers')).not_to have_selector(:table_row, %w[Other])
  end
end

Capybara::SpecHelper.spec '#has_no_table?' do
  before do
    @session.visit('/tables')
  end

  it 'should be false if the table is on the page' do
    expect(@session).not_to have_no_table('Villain')
    expect(@session).not_to have_no_table('villain_table')
  end

  it 'should be true if the table is not on the page' do
    expect(@session).to have_no_table('Monkey')
  end

  it 'should consider rows' do
    expect(@session).to have_no_table('Horizontal Headers', with_rows:
     [
       { 'First Name' => 'Thomas', 'City' => 'Los Angeles' }
     ])
  end

  context 'using :with_cols' do
    it 'should consider a single column' do
      expect(@session).to have_no_table('Vertical Headers', with_cols:
        [
          { 'First Name' => 'Joe' }
        ])
    end

    it 'should be true even if the last column does exist' do
      expect(@session).to have_no_table('Vertical Headers', with_cols:
        [
          {
            'First Name' => 'What?',
            'What?' => 'Walpole',
            'City' => 'Oceanside' # This line makes the example fail
          }
        ])
    end

    it 'should be true if none of the columns exist' do
      expect(@session).to have_no_table('Vertical Headers', with_cols:
        [
          {
            'First Name' => 'What?',
            'What?' => 'Walpole',
            'City' => 'What?'
          }
        ])
    end

    it 'should be true if the first column does match' do
      expect(@session).to have_no_table('Vertical Headers', with_cols:
        [
          {
            'First Name' => 'Thomas',
            'Last Name' => 'What',
            'City' => 'What'
          }
        ])
    end

    it 'should be true if none of the columns match' do
      expect(@session).to have_no_table('Vertical Headers', with_cols:
        [
          {
            'First Name' => 'What',
            'Last Name' => 'What',
            'City' => 'What'
          }
        ])
    end
  end
end

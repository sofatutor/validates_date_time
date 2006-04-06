require File.dirname(__FILE__) + '/abstract_unit'

class DateTest < Test::Unit::TestCase
  fixtures :people
  
  def test_no_date_checking
    assert p.update_attributes(:date_of_birth => nil, :date_of_death => nil)
    assert p.update_attributes(:date_of_visit => 'All Blacks')
  end
  
  def test_ignored
    assert p.update_attributes(:date_of_birth => '2006-01-01')
    assert p.update_attributes(:date_of_birth => '1980-10-28')
  end
  
  # Test 1/1/06 format
  def test_first_format
    assert p.update_attributes(:date_of_birth => '1/1/01')
    assert_equal '2001-01-01', p.date_of_birth.to_s
    
    assert p.update_attributes(:date_of_birth => '29/10/2005')
    assert_equal '2005-10-29', p.date_of_birth.to_s
    
    assert p.update_attributes(:date_of_birth => ' 8\12\63')
    assert_equal '1963-12-08', p.date_of_birth.to_s
    
    assert p.update_attributes(:date_of_birth => '11\1\06')
    assert_equal '2006-01-11', p.date_of_birth.to_s
    
    assert p.update_attributes(:date_of_birth => '10.6.05')
    assert_equal '2005-06-10', p.date_of_birth.to_s
    
    assert p.update_attributes(:date_of_birth => '20:9:06')
    assert_equal '2006-09-20', p.date_of_birth.to_s
    
    # Feb 30 should be invalid
    assert !p.update_attributes(:date_of_birth => '30/2/06')
  end
  
  # Test 1 Jan 06 format
  def test_second_format
    assert p.update_attributes(:date_of_birth => '16 MaR 60')
    assert_equal '1960-03-16', p.date_of_birth.to_s
    
    assert p.update_attributes(:date_of_birth => '22 dec 1985 ')
    assert_equal '1985-12-22', p.date_of_birth.to_s
    
    assert !p.update_attributes(:date_of_birth => '1 Jaw 00')
  end
  
  def test_invalid_formats
    assert !p.update_attributes(:date_of_birth => 'aksjhdaksjhd')
    assert !p.update_attributes(:date_of_birth => 'meow')
    assert !p.update_attributes(:date_of_birth => 'chocolate')
    
    assert !p.update_attributes(:date_of_birth => '221 jan 05')
    assert !p.update_attributes(:date_of_birth => '21 JAN 001')
    
    assert !p.update_attributes(:date_of_birth => '1/2/3/4')
    assert !p.update_attributes(:date_of_birth => '11/22/33')
    assert !p.update_attributes(:date_of_birth => '10/10/990')
    assert !p.update_attributes(:date_of_birth => '189 /1 /9')
    assert !p.update_attributes(:date_of_birth => '12\ f m')
  end
  
  def test_validation
    p.valid?
    p.valid?
  end
  
  def test_date_objects
    assert p.update_attributes(:date_of_birth => Date.new(2006, 1, 1))
    assert_equal '2006-01-01', p.date_of_birth.to_s
    
    assert p.update_attributes(:date_of_birth => '1 Jan 05')
    assert_equal '2005-01-01', p.date_of_birth.to_s
    
    assert p.update_attributes(:date_of_birth => Date.new(1963, 4, 5))
    assert_equal '1963-04-05', p.date_of_birth.to_s
  end
  
  def test_before_and_after
    assert p.update_attributes(:date_of_death => '1950-01-01')
    
    assert !p.update_attributes(:date_of_death => (Date.today + 2).to_s)
    assert p.errors[:date_of_death] =~ /before/
    
    assert !p.update_attributes(:date_of_death => Date.new(2030, 1, 1))
    assert p.errors[:date_of_death] =~ /before/
    
    assert p.update_attributes(:date_of_birth => '1950-01-01', :date_of_death => nil)
    
    assert !p.update_attributes(:date_of_death => '1949-01-01')
    assert p.errors[:date_of_death] =~ /after/
    assert p.update_attributes(:date_of_death => Date.new(1951, 1, 1))
  end
  
  def test_before_and_after_with_custom_message
    assert !p.update_attributes(:date_of_arrival => 2.years.from_now.to_date, :date_of_departure => 2.years.ago.to_date)
    assert p.errors[:date_of_arrival] =~ /avant/
    
    assert !p.update_attributes(:date_of_arrival => '1792-03-03')
    assert p.errors[:date_of_arrival] =~ /apres/
  end
  
  def test_dates_with_unknown_year
    assert p.update_attributes(:date_of_birth => '9999-12-11')
    assert p.update_attributes(:date_of_birth => Date.new(9999, 1, 1))
  end
end

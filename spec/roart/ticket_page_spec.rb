require File.join(File.dirname(__FILE__), %w[ .. spec_helper])

describe 'ticket page' do
  
  describe 'ticket hash' do
    
    it 'should convert an array to a hash' do
      array = ["id : 10", "subject : asdf"]
      array.extend(Roart::TicketPage)
      hash = array.to_hash
      hash.has_key?(:id).should be_true
      hash[:id].should == 10
      hash[:subject].should == 'asdf'
    end
    
    it 'should not have a history' do
      array = ["id : 10", "subject : asdf"]
      array.extend(Roart::TicketPage)
      hash = array.to_hash
      hash[:history].should be_false
    end
  
  end
  
  describe 'search array' do
    
    before do
      @array = ["123 : Subject", "234 : Subject"]
      @array.extend(Roart::TicketPage)
      @array = @array.to_search_array
    end
    
    it 'should make an array of search results' do
      @array.size.should == 2
    end
    
    it 'should put search elements into the search array' do
      @array.first[:id].should == 123
      @array.last[:id].should == 234
    end
    
    it 'should keep history false' do
      @array.first[:history].should be_false
      @array.last[:history].should be_false
    end
    
  end
  
end
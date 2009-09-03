require 'test_helper'

class GoogleOtgTest < ActiveSupport::TestCase
    include GoogleOtg

    context "GoogleOtg" do
        context "when passed in bad data" do
            should "throw ArgumentError" do
                e = nil
                begin
                    over_time_graph([:foo => "bar"])
                rescue Exception => e
                end
                
                assert_instance_of(ArgumentError, e)
            end
        end
        
        context "when passed in simple data" do
            should "print out html" do 
                hits = Hit.find(:all, :order => "created_at" )
                output = over_time_graph(hits)
                md = output.strip!.match(/^\<embed/)
                assert(md != nil)
            end
        end
        
        context "actionview is modified" do
            should "have over_time_graph method" do
                assert(ActionView::Base.instance_methods.include?("over_time_graph"))
            end
        end
    end    
    
end

class ApplicationHelperTest < ActionView::TestCase  
  def test_helper_method
    hits = Hit.find(:all, :order => "created_at" )
    tag = over_time_graph(hits)  
    assert_tag_in(tag, :embed)#, :attributes => {:href => edit_account_path})  
  end  
end  

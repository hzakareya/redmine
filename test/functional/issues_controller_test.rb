# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.dirname(__FILE__) + '/../test_helper'
require 'issues_controller'

# Re-raise errors caught by the controller.
class IssuesController; def rescue_action(e) raise e end; end

class IssuesControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries
  
  def setup
    @controller = IssuesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  def test_index
    Setting.default_language = 'en'
    
    get :index
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:project)
    assert_tag :tag => 'a', :content => /Can't print recipes/
    assert_tag :tag => 'a', :content => /Subproject issue/
    # private projects hidden
    assert_no_tag :tag => 'a', :content => /Issue of a private subproject/
    assert_no_tag :tag => 'a', :content => /Issue on project 2/
    # project column
    assert_tag :tag => 'th', :content => /Project/
  end
  
  def test_index_xml_route
    assert_routing({:method=>:get, :path=>'/projects/ecookbook/issues.xml'},
      :controller=>'issues', :action=>'index', :project_id=>'ecookbook', :format=>'xml')
  end
  
  def test_index_xml
    get :index, :format=>'xml', :project_id=>'ecookbook'
    count = 0
    @response.body.gsub(/\<issue\>/) do
      count += 1
    end
    assert_equal 6, count
  end
  
  def test_index_should_not_list_issues_when_module_disabled
    EnabledModule.delete_all("name = 'issue_tracking' AND project_id = 1")
    get :index
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:project)
    assert_no_tag :tag => 'a', :content => /Can't print recipes/
    assert_tag :tag => 'a', :content => /Subproject issue/
  end

  def test_index_should_not_list_issues_when_module_disabled
    EnabledModule.delete_all("name = 'issue_tracking' AND project_id = 1")
    get :index
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:project)
    assert_no_tag :tag => 'a', :content => /Can't print recipes/
    assert_tag :tag => 'a', :content => /Subproject issue/
  end
  
  def test_index_with_project
    Setting.display_subprojects_issues = 0
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_tag :tag => 'a', :content => /Can't print recipes/
    assert_no_tag :tag => 'a', :content => /Subproject issue/
  end
  
  def test_index_with_project_and_subprojects
    Setting.display_subprojects_issues = 1
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_tag :tag => 'a', :content => /Can't print recipes/
    assert_tag :tag => 'a', :content => /Subproject issue/
    assert_no_tag :tag => 'a', :content => /Issue of a private subproject/
  end
  
  def test_index_with_project_and_subprojects_should_show_private_subprojects
    @request.session[:user_id] = 2
    Setting.display_subprojects_issues = 1
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_tag :tag => 'a', :content => /Can't print recipes/
    assert_tag :tag => 'a', :content => /Subproject issue/
    assert_tag :tag => 'a', :content => /Issue of a private subproject/
  end
  
  def test_index_with_project_and_filter
    get :index, :project_id => 1, :set_filter => 1
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
  end
  
  def test_index_with_query
    get :index, :project_id => 1, :query_id => 5
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:issue_count_by_group)
  end
  
  def test_index_with_query_grouped_by_tracker
    get :index, :project_id => 1, :query_id => 6
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_not_nil assigns(:issue_count_by_group)
  end
  
  def test_index_with_query_grouped_by_list_custom_field
    get :index, :project_id => 1, :query_id => 9
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_not_nil assigns(:issue_count_by_group)
  end
  
  def test_index_sort_by_field_not_included_in_columns
    Setting.issue_list_default_columns = %w(subject author)
    get :index, :sort => 'tracker'
  end
  
  def test_index_csv_with_project
    Setting.default_language = 'en'
    
    get :index, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'text/csv', @response.content_type
    assert @response.body.starts_with?("#,")

    get :index, :project_id => 1, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'text/csv', @response.content_type
  end
  
  def test_index_pdf
    get :index, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'application/pdf', @response.content_type
    
    get :index, :project_id => 1, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'application/pdf', @response.content_type
    
    get :index, :project_id => 1, :query_id => 6, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'application/pdf', @response.content_type
  end
  
  def test_index_pdf_with_query_grouped_by_list_custom_field
    get :index, :project_id => 1, :query_id => 9, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_not_nil assigns(:issue_count_by_group)
    assert_equal 'application/pdf', @response.content_type
  end
  
  def test_index_sort
    get :index, :sort => 'tracker,id:desc'
    assert_response :success
    
    sort_params = @request.session['issues_index_sort']
    assert sort_params.is_a?(String)
    assert_equal 'tracker,id:desc', sort_params
    
    issues = assigns(:issues)
    assert_not_nil issues
    assert !issues.empty?
    assert_equal issues.sort {|a,b| a.tracker == b.tracker ? b.id <=> a.id : a.tracker <=> b.tracker }.collect(&:id), issues.collect(&:id)
  end
  
  def test_index_with_columns
    columns = ['tracker', 'subject', 'assigned_to']
    get :index, :set_filter => 1, :query => { 'column_names' => columns}
    assert_response :success
    
    # query should use specified columns
    query = assigns(:query)
    assert_kind_of Query, query
    assert_equal columns, query.column_names.map(&:to_s)
    
    # columns should be stored in session
    assert_kind_of Hash, session[:query]
    assert_kind_of Array, session[:query][:column_names]
    assert_equal columns, session[:query][:column_names].map(&:to_s)
  end

  def test_gantt
    get :gantt, :project_id => 1
    assert_response :success
    assert_template 'gantt.rhtml'
    assert_not_nil assigns(:gantt)
    events = assigns(:gantt).events
    assert_not_nil events
    # Issue with start and due dates
    i = Issue.find(1)
    assert_not_nil i.due_date
    assert events.include?(Issue.find(1))
    # Issue with without due date but targeted to a version with date
    i = Issue.find(2)
    assert_nil i.due_date
    assert events.include?(i)
  end

  def test_cross_project_gantt
    get :gantt
    assert_response :success
    assert_template 'gantt.rhtml'
    assert_not_nil assigns(:gantt)
    events = assigns(:gantt).events
    assert_not_nil events
  end

  def test_gantt_export_to_pdf
    get :gantt, :project_id => 1, :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
    assert @response.body.starts_with?('%PDF')
    assert_not_nil assigns(:gantt)
  end

  def test_cross_project_gantt_export_to_pdf
    get :gantt, :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
    assert @response.body.starts_with?('%PDF')
    assert_not_nil assigns(:gantt)
  end
  
  if Object.const_defined?(:Magick)
    def test_gantt_image
      get :gantt, :project_id => 1, :format => 'png'
      assert_response :success
      assert_equal 'image/png', @response.content_type
    end
  else
    puts "RMagick not installed. Skipping tests !!!"
  end
  
  def test_calendar
    get :calendar, :project_id => 1
    assert_response :success
    assert_template 'calendar'
    assert_not_nil assigns(:calendar)
  end
  
  def test_cross_project_calendar
    get :calendar
    assert_response :success
    assert_template 'calendar'
    assert_not_nil assigns(:calendar)
  end
  
  def test_changes
    get :changes, :project_id => 1
    assert_response :success
    assert_not_nil assigns(:journals)
    assert_equal 'application/atom+xml', @response.content_type
  end
  
  def test_show_by_anonymous
    get :show, :id => 1
    assert_response :success
    assert_template 'show.rhtml'
    assert_not_nil assigns(:issue)
    assert_equal Issue.find(1), assigns(:issue)
    
    # anonymous role is allowed to add a note
    assert_tag :tag => 'form',
               :descendant => { :tag => 'fieldset',
                                :child => { :tag => 'legend', 
                                            :content => /Notes/ } }
  end
  
  def test_show_by_manager
    @request.session[:user_id] = 2
    get :show, :id => 1
    assert_response :success
    
    assert_tag :tag => 'form',
               :descendant => { :tag => 'fieldset',
                                :child => { :tag => 'legend', 
                                            :content => /Change properties/ } },
               :descendant => { :tag => 'fieldset',
                                :child => { :tag => 'legend', 
                                            :content => /Log time/ } },
               :descendant => { :tag => 'fieldset',
                                :child => { :tag => 'legend', 
                                            :content => /Notes/ } }
  end
  
  def test_show_should_deny_anonymous_access_without_permission
    Role.anonymous.remove_permission!(:view_issues)
    get :show, :id => 1
    assert_response :redirect
  end
  
  def test_show_should_deny_non_member_access_without_permission
    Role.non_member.remove_permission!(:view_issues)
    @request.session[:user_id] = 9
    get :show, :id => 1
    assert_response 403
  end
  
  def test_show_should_deny_member_access_without_permission
    Role.find(1).remove_permission!(:view_issues)
    @request.session[:user_id] = 2
    get :show, :id => 1
    assert_response 403
  end
  
  def test_show_should_not_disclose_relations_to_invisible_issues
    Setting.cross_project_issue_relations = '1'
    IssueRelation.create!(:issue_from => Issue.find(1), :issue_to => Issue.find(2), :relation_type => 'relates')
    # Relation to a private project issue
    IssueRelation.create!(:issue_from => Issue.find(1), :issue_to => Issue.find(4), :relation_type => 'relates')
    
    get :show, :id => 1
    assert_response :success
    
    assert_tag :div, :attributes => { :id => 'relations' },
                     :descendant => { :tag => 'a', :content => /#2$/ }
    assert_no_tag :div, :attributes => { :id => 'relations' },
                        :descendant => { :tag => 'a', :content => /#4$/ }
  end
  
  def test_show_atom
    get :show, :id => 2, :format => 'atom'
    assert_response :success
    assert_template 'changes.rxml'
    # Inline image
    assert_select 'content', :text => Regexp.new(Regexp.quote('http://test.host/attachments/download/10'))
  end
  
  def test_show_export_to_pdf
    get :show, :id => 3, :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
    assert @response.body.starts_with?('%PDF')
    assert_not_nil assigns(:issue)
  end

  def test_get_new
    @request.session[:user_id] = 2
    get :new, :project_id => 1, :tracker_id => 1
    assert_response :success
    assert_template 'new'
    
    assert_tag :tag => 'input', :attributes => { :name => 'issue[custom_field_values][2]',
                                                 :value => 'Default string' }
  end

  def test_get_new_without_tracker_id
    @request.session[:user_id] = 2
    get :new, :project_id => 1
    assert_response :success
    assert_template 'new'
    
    issue = assigns(:issue)
    assert_not_nil issue
    assert_equal Project.find(1).trackers.first, issue.tracker
  end
  
  def test_get_new_with_no_default_status_should_display_an_error
    @request.session[:user_id] = 2
    IssueStatus.delete_all
    
    get :new, :project_id => 1
    assert_response 500
    assert_not_nil flash[:error]
    assert_tag :tag => 'div', :attributes => { :class => /error/ },
                              :content => /No default issue/
  end
  
  def test_get_new_with_no_tracker_should_display_an_error
    @request.session[:user_id] = 2
    Tracker.delete_all
    
    get :new, :project_id => 1
    assert_response 500
    assert_not_nil flash[:error]
    assert_tag :tag => 'div', :attributes => { :class => /error/ },
                              :content => /No tracker/
  end
  
  def test_update_new_form
    @request.session[:user_id] = 2
    xhr :post, :update_form, :project_id => 1,
                     :issue => {:tracker_id => 2, 
                                :subject => 'This is the test_new issue',
                                :description => 'This is the description',
                                :priority_id => 5}
    assert_response :success
    assert_template 'attributes'
    
    issue = assigns(:issue)
    assert_kind_of Issue, issue
    assert_equal 1, issue.project_id
    assert_equal 2, issue.tracker_id
    assert_equal 'This is the test_new issue', issue.subject
  end
  
  def test_post_new
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :new, :project_id => 1, 
                 :issue => {:tracker_id => 3,
                            :status_id => 2,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :estimated_hours => '',
                            :custom_field_values => {'2' => 'Value for field 2'}}
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id
    
    issue = Issue.find_by_subject('This is the test_new issue')
    assert_not_nil issue
    assert_equal 2, issue.author_id
    assert_equal 3, issue.tracker_id
    assert_equal 2, issue.status_id
    assert_nil issue.estimated_hours
    v = issue.custom_values.find(:first, :conditions => {:custom_field_id => 2})
    assert_not_nil v
    assert_equal 'Value for field 2', v.value
  end
  
  def test_post_new_and_continue
    @request.session[:user_id] = 2
    post :new, :project_id => 1, 
               :issue => {:tracker_id => 3,
                          :subject => 'This is first issue',
                          :priority_id => 5},
               :continue => ''
    assert_redirected_to :controller => 'issues', :action => 'new', :issue => {:tracker_id => 3}
  end
  
  def test_post_new_without_custom_fields_param
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :new, :project_id => 1, 
                 :issue => {:tracker_id => 1,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5}
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id
  end

  def test_post_new_with_required_custom_field_and_without_custom_fields_param
    field = IssueCustomField.find_by_name('Database')
    field.update_attribute(:is_required, true)

    @request.session[:user_id] = 2
    post :new, :project_id => 1, 
               :issue => {:tracker_id => 1,
                          :subject => 'This is the test_new issue',
                          :description => 'This is the description',
                          :priority_id => 5}
    assert_response :success
    assert_template 'new'
    issue = assigns(:issue)
    assert_not_nil issue
    assert_equal I18n.translate('activerecord.errors.messages.invalid'), issue.errors.on(:custom_values)
  end
  
  def test_post_new_with_watchers
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    
    assert_difference 'Watcher.count', 2 do
      post :new, :project_id => 1, 
                 :issue => {:tracker_id => 1,
                            :subject => 'This is a new issue with watchers',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :watcher_user_ids => ['2', '3']}
    end
    issue = Issue.find_by_subject('This is a new issue with watchers')
    assert_not_nil issue
    assert_redirected_to :controller => 'issues', :action => 'show', :id => issue
    
    # Watchers added
    assert_equal [2, 3], issue.watcher_user_ids.sort
    assert issue.watched_by?(User.find(3))
    # Watchers notified
    mail = ActionMailer::Base.deliveries.last
    assert_kind_of TMail::Mail, mail
    assert [mail.bcc, mail.cc].flatten.include?(User.find(3).mail)
  end
  
  def test_post_new_subissue
    @request.session[:user_id] = 2
    
    assert_difference 'Issue.count' do
      post :new, :project_id => 1, 
                 :issue => {:tracker_id => 1,
                            :subject => 'This is a child issue',
                            :parent_issue_id => 2}
    end
    issue = Issue.find_by_subject('This is a child issue')
    assert_not_nil issue
    assert_equal Issue.find(2), issue.parent
  end
  
  def test_post_new_should_send_a_notification
    ActionMailer::Base.deliveries.clear
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :new, :project_id => 1, 
                 :issue => {:tracker_id => 3,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :estimated_hours => '',
                            :custom_field_values => {'2' => 'Value for field 2'}}
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id
    
    assert_equal 1, ActionMailer::Base.deliveries.size
  end
  
  def test_post_should_preserve_fields_values_on_validation_failure
    @request.session[:user_id] = 2
    post :new, :project_id => 1, 
               :issue => {:tracker_id => 1,
                          # empty subject
                          :subject => '',
                          :description => 'This is a description',
                          :priority_id => 6,
                          :custom_field_values => {'1' => 'Oracle', '2' => 'Value for field 2'}}
    assert_response :success
    assert_template 'new'
    
    assert_tag :textarea, :attributes => { :name => 'issue[description]' },
                          :content => 'This is a description'
    assert_tag :select, :attributes => { :name => 'issue[priority_id]' },
                        :child => { :tag => 'option', :attributes => { :selected => 'selected',
                                                                       :value => '6' },
                                                      :content => 'High' }  
    # Custom fields
    assert_tag :select, :attributes => { :name => 'issue[custom_field_values][1]' },
                        :child => { :tag => 'option', :attributes => { :selected => 'selected',
                                                                       :value => 'Oracle' },
                                                      :content => 'Oracle' }  
    assert_tag :input, :attributes => { :name => 'issue[custom_field_values][2]',
                                        :value => 'Value for field 2'}
  end
  
  def test_post_new_should_ignore_non_safe_attributes
    @request.session[:user_id] = 2
    assert_nothing_raised do
      post :new, :project_id => 1, :issue => { :tracker => "A param can not be a Tracker" }
    end
  end
  
  context "without workflow privilege" do
    setup do
      Workflow.delete_all(["role_id = ?", Role.anonymous.id])
      Role.anonymous.add_permission! :add_issues
    end
    
    context "#new" do
      should "propose default status only" do
        get :new, :project_id => 1
        assert_response :success
        assert_template 'new'
        assert_tag :tag => 'select',
          :attributes => {:name => 'issue[status_id]'},
          :children => {:count => 1},
          :child => {:tag => 'option', :attributes => {:value => IssueStatus.default.id.to_s}}
      end
      
      should "accept default status" do
        assert_difference 'Issue.count' do
          post :new, :project_id => 1, 
                     :issue => {:tracker_id => 1,
                                :subject => 'This is an issue',
                                :status_id => 1}
        end
        issue = Issue.last(:order => 'id')
        assert_equal IssueStatus.default, issue.status
      end
      
      should "ignore unauthorized status" do
        assert_difference 'Issue.count' do
          post :new, :project_id => 1, 
                     :issue => {:tracker_id => 1,
                                :subject => 'This is an issue',
                                :status_id => 3}
        end
        issue = Issue.last(:order => 'id')
        assert_equal IssueStatus.default, issue.status
      end
    end
  end
  
  def test_copy_issue
    @request.session[:user_id] = 2
    get :new, :project_id => 1, :copy_from => 1
    assert_template 'new'
    assert_not_nil assigns(:issue)
    orig = Issue.find(1)
    assert_equal orig.subject, assigns(:issue).subject
  end
  
  def test_get_edit
    @request.session[:user_id] = 2
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:issue)
    assert_equal Issue.find(1), assigns(:issue)
  end
  
  def test_get_edit_with_params
    @request.session[:user_id] = 2
    get :edit, :id => 1, :issue => { :status_id => 5, :priority_id => 7 }
    assert_response :success
    assert_template 'edit'
    
    issue = assigns(:issue)
    assert_not_nil issue
    
    assert_equal 5, issue.status_id
    assert_tag :select, :attributes => { :name => 'issue[status_id]' },
                        :child => { :tag => 'option', 
                                    :content => 'Closed',
                                    :attributes => { :selected => 'selected' } }
                                    
    assert_equal 7, issue.priority_id
    assert_tag :select, :attributes => { :name => 'issue[priority_id]' },
                        :child => { :tag => 'option', 
                                    :content => 'Urgent',
                                    :attributes => { :selected => 'selected' } }
  end

  def test_update_edit_form
    @request.session[:user_id] = 2
    xhr :post, :update_form, :project_id => 1,
                             :id => 1,
                             :issue => {:tracker_id => 2, 
                                        :subject => 'This is the test_new issue',
                                        :description => 'This is the description',
                                        :billable => "1",
                                        :priority_id => 5}
    assert_response :success
    assert_template 'attributes'
    
    issue = assigns(:issue)
    assert_kind_of Issue, issue
    assert_equal 1, issue.id
    assert_equal 1, issue.project_id
    assert_equal 2, issue.tracker_id
    assert_equal true, issue.billable
    assert_equal 'This is the test_new issue', issue.subject
  end
  
  def test_reply_to_issue
    @request.session[:user_id] = 2
    get :reply, :id => 1
    assert_response :success
    assert_select_rjs :show, "update"
  end

  def test_reply_to_note
    @request.session[:user_id] = 2
    get :reply, :id => 1, :journal_id => 2
    assert_response :success
    assert_select_rjs :show, "update"
  end

  def test_update_using_invalid_http_verbs
    @request.session[:user_id] = 2
    subject = 'Updated by an invalid http verb'

    get :update, :id => 1, :issue => {:subject => subject}
    assert_not_equal subject, Issue.find(1).subject

    post :update, :id => 1, :issue => {:subject => subject}
    assert_not_equal subject, Issue.find(1).subject

    delete :update, :id => 1, :issue => {:subject => subject}
    assert_not_equal subject, Issue.find(1).subject
  end

  def test_put_update_without_custom_fields_param
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    
    issue = Issue.find(1)
    assert_equal '125', issue.custom_value_for(2).value
    old_subject = issue.subject
    new_subject = 'Subject modified by IssuesControllerTest#test_post_edit'
    
    assert_difference('Journal.count') do
      assert_difference('JournalDetail.count', 2) do
        put :update, :id => 1, :issue => {:subject => new_subject,
                                         :priority_id => '6',
                                         :category_id => '1' # no change
                                        }
      end
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue.reload
    assert_equal new_subject, issue.subject
    # Make sure custom fields were not cleared
    assert_equal '125', issue.custom_value_for(2).value
    
    mail = ActionMailer::Base.deliveries.last
    assert_kind_of TMail::Mail, mail
    assert mail.subject.starts_with?("[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}]")
    assert mail.body.include?("Subject changed from #{old_subject} to #{new_subject}")
  end
  
  def test_put_update_with_custom_field_change
    @request.session[:user_id] = 2
    issue = Issue.find(1)
    assert_equal '125', issue.custom_value_for(2).value
    
    assert_difference('Journal.count') do
      assert_difference('JournalDetail.count', 3) do
        put :update, :id => 1, :issue => {:subject => 'Custom field change',
                                         :priority_id => '6',
                                         :category_id => '1', # no change
                                         :custom_field_values => { '2' => 'New custom value' }
                                        }
      end
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue.reload
    assert_equal 'New custom value', issue.custom_value_for(2).value
    
    mail = ActionMailer::Base.deliveries.last
    assert_kind_of TMail::Mail, mail
    assert mail.body.include?("Searchable field changed from 125 to New custom value")
  end
  
  def test_put_update_with_status_and_assignee_change
    issue = Issue.find(1)
    assert_equal 1, issue.status_id
    @request.session[:user_id] = 2
    assert_difference('TimeEntry.count', 0) do
      put :update,
           :id => 1,
           :issue => { :status_id => 2, :assigned_to_ids => [3] },
           :notes => 'Assigned to dlopper',
           :time_entry => { :hours => '', :comments => '', :activity_id => TimeEntryActivity.first }
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue.reload
    assert_equal 2, issue.status_id
    j = Journal.find(:first, :order => 'id DESC')
    assert_equal 'Assigned to dlopper', j.notes
    assert_equal 2, j.details.size
    
    mail = ActionMailer::Base.deliveries.last
    assert mail.body.include?("Status changed from New to Assigned")
    # subject should contain the new status
    assert mail.subject.include?("(#{ IssueStatus.find(2).name })")
  end
  
  def test_put_update_with_note_only
    notes = 'Note added by IssuesControllerTest#test_update_with_note_only'
    # anonymous user
    put :update,
         :id => 1,
         :notes => notes
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.find(:first, :order => 'id DESC')
    assert_equal notes, j.notes
    assert_equal 0, j.details.size
    assert_equal User.anonymous, j.user
    
    mail = ActionMailer::Base.deliveries.last
    assert mail.body.include?(notes)
  end
  
  def test_put_update_with_note_and_spent_time
    @request.session[:user_id] = 2
    spent_hours_before = Issue.find(1).spent_hours
    assert_difference('TimeEntry.count') do
      put :update,
           :id => 1,
           :notes => '2.5 hours added',
           :time_entry => { :spent_from=>Time.now, :spent_to=>(2.5).hours.from_now, :comments => '', :activity_id => TimeEntryActivity.first }
    end
    assert_redirected_to :action => 'show', :id => '1'
    
    issue = Issue.find(1)
    
    j = Journal.find(:first, :order => 'id DESC')
    assert_equal '2.5 hours added', j.notes
    assert_equal 0, j.details.size
    
    t = issue.time_entries.find(:first, :order => 'id DESC')
    assert_not_nil t
    assert_equal 2.5, t.hours
    assert_equal spent_hours_before + 2.5, issue.spent_hours
  end
  
  def test_put_update_with_attachment_only
    set_tmp_attachments_directory
    
    # Delete all fixtured journals, a race condition can occur causing the wrong
    # journal to get fetched in the next find.
    Journal.delete_all

    # anonymous user
    put :update,
         :id => 1,
         :notes => '',
         :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain')}}
    assert_redirected_to :action => 'show', :id => '1'
    j = Issue.find(1).journals.find(:first, :order => 'id DESC')
    assert j.notes.blank?
    assert_equal 1, j.details.size
    assert_equal 'testfile.txt', j.details.first.value
    assert_equal User.anonymous, j.user
    
    mail = ActionMailer::Base.deliveries.last
    assert mail.body.include?('testfile.txt')
  end

  def test_put_update_with_attachment_that_fails_to_save
    set_tmp_attachments_directory
    
    # Delete all fixtured journals, a race condition can occur causing the wrong
    # journal to get fetched in the next find.
    Journal.delete_all

    # Mock out the unsaved attachment
    Attachment.any_instance.stubs(:create).returns(Attachment.new)
    
    # anonymous user
    put :update,
         :id => 1,
         :notes => '',
         :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain')}}
    assert_redirected_to :action => 'show', :id => '1'
    assert_equal '1 file(s) could not be saved.', flash[:warning]

  end if Object.const_defined?(:Mocha)

  def test_put_update_with_no_change
    issue = Issue.find(1)
    issue.journals.clear
    ActionMailer::Base.deliveries.clear
    
    put :update,
         :id => 1,
         :notes => ''
    assert_redirected_to :action => 'show', :id => '1'
    
    issue.reload
    assert issue.journals.empty?
    # No email should be sent
    assert ActionMailer::Base.deliveries.empty?
  end

  def test_put_update_should_send_a_notification
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    issue = Issue.find(1)
    old_subject = issue.subject
    new_subject = 'Subject modified by IssuesControllerTest#test_post_edit'
    
    put :update, :id => 1, :issue => {:subject => new_subject,
                                     :priority_id => '6',
                                     :category_id => '1' # no change
                                    }
    assert_equal 1, ActionMailer::Base.deliveries.size
  end
  
  def test_put_update_with_invalid_spent_time
    @request.session[:user_id] = 2
    notes = 'Note added by IssuesControllerTest#test_post_edit_with_invalid_spent_time'
    
    assert_no_difference('Journal.count') do
      put :update,
           :id => 1,
           :notes => notes,
           :time_entry => {"comments"=>"", "activity_id"=>"", "hours"=>"2z"}
    end
    assert_response :success
    assert_template 'edit'
    
    assert_tag :textarea, :attributes => { :name => 'notes' },
                          :content => notes
    #assert_tag :input, :attributes => { :name => 'time_entry[hours]', :value => "2z" }
  end
  
  def test_put_update_should_allow_fixed_version_to_be_set_to_a_subproject
    issue = Issue.find(2)
    @request.session[:user_id] = 2

    put :update,
         :id => issue.id,
         :issue => {
           :fixed_version_id => 4
         }

    assert_response :redirect
    issue.reload
    assert_equal 4, issue.fixed_version_id
    assert_not_equal issue.project_id, issue.fixed_version.project_id
  end

  def test_put_update_should_redirect_back_using_the_back_url_parameter
    issue = Issue.find(2)
    @request.session[:user_id] = 2

    put :update,
         :id => issue.id,
         :issue => {
           :fixed_version_id => 4
         },
         :back_url => '/issues'

    assert_response :redirect
    assert_redirected_to '/issues'
  end
  
  def test_put_update_should_not_redirect_back_using_the_back_url_parameter_off_the_host
    issue = Issue.find(2)
    @request.session[:user_id] = 2

    put :update,
         :id => issue.id,
         :issue => {
           :fixed_version_id => 4
         },
         :back_url => 'http://google.com'

    assert_response :redirect
    assert_redirected_to :controller => 'issues', :action => 'show', :id => issue.id
  end
  
  def test_get_bulk_edit
    @request.session[:user_id] = 2
    get :bulk_edit, :ids => [1, 2]
    assert_response :success
    assert_template 'bulk_edit'
    
    # Project specific custom field, date type
    field = CustomField.find(9)
    assert !field.is_for_all?
    assert_equal 'date', field.field_format
    assert_tag :input, :attributes => {:name => 'issue[custom_field_values][9]'}
    
    # System wide custom field
    assert CustomField.find(1).is_for_all?
    assert_tag :select, :attributes => {:name => 'issue[custom_field_values][1]'}
  end

  def test_bulk_edit
    @request.session[:user_id] = 2
    # update issues priority
    post :bulk_edit, :ids => [1, 2], :notes => 'Bulk editing',
                                     :issue => {:priority_id => 7,
                                                :assigned_to_id => '',
                                                :custom_field_values => {'2' => ''}}
                                     
    assert_response 302
    # check that the issues were updated
    assert_equal [7, 7], Issue.find_all_by_id([1, 2]).collect {|i| i.priority.id}
    
    issue = Issue.find(1)
    journal = issue.journals.find(:first, :order => 'created_on DESC')
    assert_equal '125', issue.custom_value_for(2).value
    assert_equal 'Bulk editing', journal.notes
    assert_equal 1, journal.details.size
  end

  def test_bullk_edit_should_send_a_notification
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    post(:bulk_edit,
         {
           :ids => [1, 2],
           :notes => 'Bulk editing',
           :issue => {
             :priority_id => 7,
             :assigned_to_id => '',
             :custom_field_values => {'2' => ''}
           }
         })

    assert_response 302
    assert_equal 2, ActionMailer::Base.deliveries.size
  end

  def test_bulk_edit_status
    @request.session[:user_id] = 2
    # update issues priority
    post :bulk_edit, :ids => [1, 2], :notes => 'Bulk editing status',
                                     :issue => {:priority_id => '',
                                                :assigned_to_id => '',
                                                :status_id => '5'}
                                     
    assert_response 302
    issue = Issue.find(1)
    assert issue.closed?
  end

  def test_bulk_edit_custom_field
    @request.session[:user_id] = 2
    # update issues priority
    post :bulk_edit, :ids => [1, 2], :notes => 'Bulk editing custom field',
                                     :issue => {:priority_id => '',
                                                :assigned_to_id => '',
                                                :custom_field_values => {'2' => '777'}}
                                     
    assert_response 302
    
    issue = Issue.find(1)
    journal = issue.journals.find(:first, :order => 'created_on DESC')
    assert_equal '777', issue.custom_value_for(2).value
    assert_equal 1, journal.details.size
    assert_equal '125', journal.details.first.old_value
    assert_equal '777', journal.details.first.value
  end

  def test_bulk_unassign
    assert_not_nil Issue.find(2).assigned_to
    @request.session[:user_id] = 2
    # unassign issues
  post :bulk_edit, :ids => [1, 2], :notes => 'Bulk unassigning', :issue => {:assigned_to_ids => 'none'}
    assert_response 302
    # check that the issues were updated
    assert Issue.find(2).assigned_to.empty?
  end
  
  def test_post_bulk_edit_should_allow_fixed_version_to_be_set_to_a_subproject
    @request.session[:user_id] = 2

    post :bulk_edit, :ids => [1,2], :issue => {:fixed_version_id => 4}

    assert_response :redirect
    issues = Issue.find([1,2])
    issues.each do |issue|
      assert_equal 4, issue.fixed_version_id
      assert_not_equal issue.project_id, issue.fixed_version.project_id
    end
  end

  def test_post_bulk_edit_should_redirect_back_using_the_back_url_parameter
    @request.session[:user_id] = 2
    post :bulk_edit, :ids => [1,2], :back_url => '/issues'

    assert_response :redirect
    assert_redirected_to '/issues'
  end

  def test_post_bulk_edit_should_not_redirect_back_using_the_back_url_parameter_off_the_host
    @request.session[:user_id] = 2
    post :bulk_edit, :ids => [1,2], :back_url => 'http://google.com'

    assert_response :redirect
    assert_redirected_to :controller => 'issues', :action => 'index', :project_id => Project.find(1).identifier
  end

  def test_move_one_issue_to_another_project
    @request.session[:user_id] = 2
    post :move, :id => 1, :new_project_id => 2, :tracker_id => '', :assigned_to_id => '', :status_id => '', :start_date => '', :due_date => ''
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_equal 2, Issue.find(1).project_id
  end

  def test_move_one_issue_to_another_project_should_follow_when_needed
    @request.session[:user_id] = 2
    post :move, :id => 1, :new_project_id => 2, :follow => '1'
    assert_redirected_to '/issues/1'
  end

  def test_bulk_move_to_another_project
    @request.session[:user_id] = 2
    post :move, :ids => [1, 2], :new_project_id => 2
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    # Issues moved to project 2
    assert_equal 2, Issue.find(1).project_id
    assert_equal 2, Issue.find(2).project_id
    # No tracker change
    assert_equal 1, Issue.find(1).tracker_id
    assert_equal 2, Issue.find(2).tracker_id
  end
 
  def test_bulk_move_to_another_tracker
    @request.session[:user_id] = 2
    post :move, :ids => [1, 2], :new_tracker_id => 2
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_equal 2, Issue.find(1).tracker_id
    assert_equal 2, Issue.find(2).tracker_id
  end

  def test_bulk_copy_to_another_project
    @request.session[:user_id] = 2
    assert_difference 'Issue.count', 2 do
      assert_no_difference 'Project.find(1).issues.count' do
        post :move, :ids => [1, 2], :new_project_id => 2, :copy_options => {:copy => '1'}
      end
    end
    assert_redirected_to 'projects/ecookbook/issues'
  end

  context "#move via bulk copy" do
    should "allow not changing the issue's attributes" do
      @request.session[:user_id] = 2
      issue_before_move = Issue.find(1)
      assert_difference 'Issue.count', 1 do
        assert_no_difference 'Project.find(1).issues.count' do
          post :move, :ids => [1], :new_project_id => 2, :copy_options => {:copy => '1'}, :new_tracker_id => '', :assigned_to_ids => '', :status_id => '', :start_date => '', :due_date => ''
        end
      end
      issue_after_move = Issue.first(:order => 'id desc', :conditions => {:project_id => 2})
      assert_equal issue_before_move.tracker_id, issue_after_move.tracker_id
      assert_equal issue_before_move.status_id, issue_after_move.status_id
      assert_equal issue_before_move.assigned_to_ids, issue_after_move.assigned_to_ids
    end
    
    should "allow changing the issue's attributes" do
      @request.session[:user_id] = 2
      assert_difference 'Issue.count', 2 do
        assert_no_difference 'Project.find(1).issues.count' do
          post :move, :ids => [1, 2], :new_project_id => 2, :copy_options => {:copy => '1'}, :new_tracker_id => '', :assigned_to_ids => [4], :status_id => 3, :start_date => '2009-12-01', :due_date => '2009-12-31'
        end
      end

      copied_issues = Issue.all(:limit => 2, :order => 'id desc', :conditions => {:project_id => 2})
      assert_equal 2, copied_issues.size
      copied_issues.each do |issue|
        assert_equal 2, issue.project_id, "Project is incorrect"
        assert_equal [4], issue.assigned_to_ids, "Assigned to is incorrect"
        assert_equal 3, issue.status_id, "Status is incorrect"
        assert_equal '2009-12-01', issue.start_date.to_s, "Start date is incorrect"
        assert_equal '2009-12-31', issue.due_date.to_s, "Due date is incorrect"
      end
    end
  end
  
  def test_bulk_billable
    @request.session[:user_id] = 2
    post :bulk_edit, :ids => [1, 2], :billable => 'billable'
    assert_redirected_to 'projects/ecookbook/issues'
    assert Issue.find(1).billable
    assert Issue.find(2).billable
  end
  
  def test_copy_to_another_project_should_follow_when_needed
    @request.session[:user_id] = 2
    post :move, :ids => [1], :new_project_id => 2, :copy_options => {:copy => '1'}, :follow => '1'
    issue = Issue.first(:order => 'id DESC')
    assert_redirected_to :controller => 'issues', :action => 'show', :id => issue
  end
  
  def test_context_menu_one_issue
    @request.session[:user_id] = 2
    get :context_menu, :ids => [1]
    assert_response :success
    assert_template 'context_menu'
    assert_tag :tag => 'a', :content => 'Edit',
                            :attributes => { :href => '/issues/1/edit',
                                             :class => 'icon-edit' }
    assert_tag :tag => 'a', :content => 'Closed',
                            :attributes => { :href => '/issues/1/edit?issue%5Bstatus_id%5D=5',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Immediate',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;issue%5Bpriority_id%5D=8',
                                             :class => '' }
    # Versions
    assert_tag :tag => 'a', :content => '2.0',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;issue%5Bfixed_version_id%5D=3',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'eCookbook Subproject 1 - 2.0',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;issue%5Bfixed_version_id%5D=4',
                                             :class => '' }

    assert_tag :tag => 'a', :content => 'Dave Lopper',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;issue%5Bassigned_to_id%5D=3',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Duplicate',
                            :attributes => { :href => '/projects/ecookbook/issues/1/copy',
                                             :class => 'icon-duplicate' }
    assert_tag :tag => 'a', :content => 'Copy',
                            :attributes => { :href => '/issues/move?copy_options%5Bcopy%5D=t&amp;ids%5B%5D=1',
                                             :class => 'icon-copy' }
    assert_tag :tag => 'a', :content => 'Move',
                            :attributes => { :href => '/issues/move?ids%5B%5D=1',
                                             :class => 'icon-move' }
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => '/issues/destroy?ids%5B%5D=1',
                                             :class => 'icon-del' }
  end

  def test_context_menu_one_issue_by_anonymous
    get :context_menu, :ids => [1]
    assert_response :success
    assert_template 'context_menu'
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => '#',
                                             :class => 'icon-del disabled' }
  end
  
  def test_context_menu_multiple_issues_of_same_project
    @request.session[:user_id] = 2
    get :context_menu, :ids => [1, 2]
    assert_response :success
    assert_template 'context_menu'
    assert_tag :tag => 'a', :content => 'Edit',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;ids%5B%5D=2',
                                             :class => 'icon-edit' }
    assert_tag :tag => 'a', :content => 'Immediate',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;ids%5B%5D=2&amp;issue%5Bpriority_id%5D=8',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Dave Lopper',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;ids%5B%5D=2&amp;issue%5Bassigned_to_id%5D=3',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Copy',
                            :attributes => { :href => '/issues/move?copy_options%5Bcopy%5D=t&amp;ids%5B%5D=1&amp;ids%5B%5D=2',
                                             :class => 'icon-copy' }
    assert_tag :tag => 'a', :content => 'Move',
                            :attributes => { :href => '/issues/move?ids%5B%5D=1&amp;ids%5B%5D=2',
                                             :class => 'icon-move' }
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => '/issues/destroy?ids%5B%5D=1&amp;ids%5B%5D=2',
                                             :class => 'icon-del' }
  end

  def test_context_menu_multiple_issues_of_different_project
    @request.session[:user_id] = 2
    get :context_menu, :ids => [1, 2, 4]
    assert_response :success
    assert_template 'context_menu'
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => '#',
                                             :class => 'icon-del disabled' }
  end
  
  def test_preview_new_issue
    @request.session[:user_id] = 2
    post :preview, :project_id => '1', :issue => {:description => 'Foo'}
    assert_response :success
    assert_template 'preview'
    assert_not_nil assigns(:description)
  end
                              
  def test_preview_notes
    @request.session[:user_id] = 2
    post :preview, :project_id => '1', :id => 1, :issue => {:description => Issue.find(1).description}, :notes => 'Foo'
    assert_response :success
    assert_template 'preview'
    assert_not_nil assigns(:notes)
  end

  def test_auto_complete_routing
    assert_routing(
      {:method => :get, :path => '/issues/auto_complete'},
      :controller => 'issues', :action => 'auto_complete'
    )
  end
  
  def test_auto_complete_should_not_be_case_sensitive
    get :auto_complete, :project_id => 'ecookbook', :q => 'ReCiPe'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert assigns(:issues).detect {|issue| issue.subject.match /recipe/}
  end
  
  def test_auto_complete_should_return_issue_with_given_id
    get :auto_complete, :project_id => 'subproject1', :q => '13'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert assigns(:issues).include?(Issue.find(13))
  end
  
  def test_destroy_routing
    assert_recognizes( #TODO: use DELETE on issue URI (need to change forms)
      {:controller => 'issues', :action => 'destroy', :id => '1'},
      {:method => :post, :path => '/issues/1/destroy'}
    )
  end
  
  def test_destroy_issue_with_no_time_entries
    assert_nil TimeEntry.find_by_issue_id(2)
    @request.session[:user_id] = 2
    post :destroy, :id => 2
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_nil Issue.find_by_id(2)
  end

  def test_destroy_issues_with_time_entries
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3]
    assert_response :success
    assert_template 'destroy'
    assert_not_nil assigns(:hours)
    assert Issue.find_by_id(1) && Issue.find_by_id(3)
  end

  def test_destroy_issues_and_destroy_time_entries
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3], :todo => 'destroy'
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_nil TimeEntry.find_by_id([1, 2])
  end

  def test_destroy_issues_and_assign_time_entries_to_project
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3], :todo => 'nullify'
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_nil TimeEntry.find(1).issue_id
    assert_nil TimeEntry.find(2).issue_id
  end
  
  def test_destroy_issues_and_reassign_time_entries_to_another_issue
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3], :todo => 'reassign', :reassign_to_id => 2
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_equal 2, TimeEntry.find(1).issue_id
    assert_equal 2, TimeEntry.find(2).issue_id
  end
  
  def test_default_search_scope
    get :index
    assert_tag :div, :attributes => {:id => 'quick-search'},
                     :child => {:tag => 'form',
                                :child => {:tag => 'input', :attributes => {:name => 'issues', :type => 'hidden', :value => '1'}}}
  end
end

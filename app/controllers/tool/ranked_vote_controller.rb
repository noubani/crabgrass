
$: << "#{RAILS_ROOT}/lib/rubyvote/lib"
require 'condorcet'

class Tool::RankedVoteController < Tool::BaseController

  stylesheet 'vote'
      
  def show
    redirect_to(page_url(@page, :action => 'edit')) unless @poll.possibles.any?
    
    @result = CloneproofSSDVote.new( build_vote_array ).result
    @possibles = @poll.possibles.sort_by do |possible|
      @result.rank_of_candidate(possible.name) || 10000
    end
    @winners = @possibles.select{|p| @result.winners.include? p.name}
  end

  def edit
    @possibles = @poll.possibles.sort_by do |pos|
      default_for_unvoted = @poll.possibles.size + rand(@poll.possibles.size)
      pos.value_by_user(current_user, default_for_unvoted)
    end
  end
    
  # ajax or post
  def add_possible
    return if request.get?
    @possible = @poll.possibles.create params[:possible]
    if @poll.valid? and @possible.valid?
      @page.unresolve
      redirect_to page_url(@page) unless request.xhr?
    else
      @poll.possibles.delete(@possible)
      message :object => @possible unless @possible.valid?
      message :object => @poll unless @poll.valid?
      if request.post? 
        render :action => 'show'
      else
        render :text => 'error', :status => 500
      end
      return
    end
  end
    
  # ajax only, returns nothing
  # for this to work, there must be a <ul id='sort_list_xxx'> element
  # and it must be declared sortable like this:
  # <%= sortable_element 'sort_list_xxx', .... %>
  def sort
    sort_list_key = params.keys.grep(/^sort_list/)
    return unless sort_list_key.any?
    
    @poll.delete_votes_by_user(current_user)
    ids = params[sort_list_key[0]]
    @poll.possibles.each do |possible|
      rank = ids.index( possible.id.to_s )
      possible.votes.create :user => current_user, :value => rank if rank
    end
    render :nothing => true
  end
  
  def update_possible
    return unless request.xhr?
    @possible = @poll.possibles.find(params[:id])
    params[:possible].delete('name')
    @possible.update_attributes(params[:possible])
  end
    
  def edit_possible
    return unless request.xhr?
    @possible = @poll.possibles.find(params[:id])
  end

  def destroy_possible    
    possible = @poll.possibles.find(params[:id])
    possible.destroy
    render :nothing => true
  end
  
  protected

  def build_vote_array
    ## first, build hash of votes
    ## the key is the user's id and the element is an array of all their votes
    ## (this should be changed if we start caching User.find(id)
    possibles = @poll.possibles.find(:all, :include => {:votes => :user})
    hash = {}
    @who_voted_for = {}
    possibles.each do |possible|
      possible.votes.each do |vote|
        hash[vote.user_id] ||= []
        hash[vote.user_id] << [possible.name, vote.value]
        if vote.value == 0
          @who_voted_for[possible.name] ||= []
          @who_voted_for[possible.name] << vote.user.name
        end
      end  
    end
    
    ## second, build array of votes. each element is an array of a user's
    ## votes, sorted by their preference
    ## eg. [ ["A", "B"],  ["B", "A"], ["B", "A"] ]
    array = []
    hash.each_value do |votes|
      array << votes.sort_by{|vote|vote[1]}.collect{|vote|vote[0]}
    end
    return array
  end
  
  def authorized?
    return super unless @page
    current_user.may?(:admin, @page)
  end  
  
  before_filter :fetch_poll
  def fetch_poll
    @poll = @page.data if @page
    true
  end

end
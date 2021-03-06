class InvitationsController < ApplicationController
  def index
    @user = current_user
    @invitations_sents = @user.invitations_sent.where(confirmed: false).order(created_at: :asc)
    @invitations_receiveds = @user.invitations_received.where(confirmed: false).order(created_at: :asc)
  end

  def find_user
    @user = current_user
  end

  def show
    @user = current_user
    @invitation = Invitation.find(params[:id])
    @suggestions = @invitation.suggestions
    @appointment = Appointment.new

    today = Date.today
    @availables = []
    for i in 0..7 do
      @availables << today + i
    end
    upcoming_appointments = @user.appointments.upcoming
    for v in upcoming_appointments do
      @availables.delete(v.day)
    end
  end

  def new
    @inviter = current_user
    @invitation = Invitation.new
    @inviter_suggestions = @inviter.suggestions.where(taken: false)

    @invitee_tel = params[:tel].delete("-")
    if @invitee_tel.length < 10
      flash[:error] = "Invalid number."
      redirect_to user_find_user_path(@inviter)
      return
    end

    @invitee = User.find_by_telephone(@invitee_tel)
    if @invitee && @invitee == @inviter
      flash[:error] = "You can't ask yourself out."
      redirect_to user_find_user_path(@inviter)
      return
    elsif @invitee
      @invitee_suggestions = @invitee.suggestions.where(public: true).where(taken: false)
      flash[:notice] = "#{@invitee.name} public places were added to this invitation."
    end

    today = Date.today
    @availables = []
    for i in 0..7 do
      @availables << today + i
    end
    upcoming_appointments = @inviter.appointments.upcoming
    for v in upcoming_appointments do
      @availables.delete(v.day)
    end
  end

  def create
    @inviter = current_user
    @invitation = Invitation.new
    @invitation.inviter = @inviter
    invitee_tel = params[:invitee_tel].delete("-")
    @invitation.invitee_tel = invitee_tel
    @invitee = User.find_by_telephone(invitee_tel)
    if @invitee
      @invitation.invitee = @invitee
      @invitation.invitee_name = @invitee.name
    end
    suggestions_id = params[:suggestions_id].split
    for id in suggestions_id
      @invitation.suggestions << Suggestion.find(id)
    end
    @invitation.days_inviter = params[:availables_id].split

    if @invitation.save
      @invitation.send_text_message
      flash[:notice] = "Invitation created successfully, a text message was sent to #{invitee_tel}"
      redirect_to user_invitations_path(@inviter)
    else
      flash[:alert] = "Invitation failed to create."
      redirect_to user_invitations_path(@inviter)
    end
  end

  def edit
  end

  def update
  end

  def destroy
    @invitation = Invitation.find(params[:id])

    if @invitation.destroy
      flash[:alert] = "Invitation deleted"
      redirect_to user_invitations_path(current_user)
    else
      flash[:error] = "Wasn't able to delete invitation"
      redirect_to user_invitations_path(current_user)
    end
  end

end

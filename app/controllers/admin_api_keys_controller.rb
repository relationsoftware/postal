# frozen_string_literal: true

class AdminAPIKeysController < ApplicationController

  before_action :admin_required

  def index
    @keys = AdminAPIKey.all.order(created_at: :desc)
  end

  def new
    @key = AdminAPIKey.new
  end

  def create
    @key = AdminAPIKey.new(params.require(:admin_api_key).permit(:name))
    @key.user = current_user
    if @key.save
      redirect_to admin_api_key_path(@key.uuid)
    else
      render "new"
    end
  end

  def show
    @key = AdminAPIKey.find_by_uuid!(params[:id])
    # We only show the full key if it was created very recently (e.g. within the last minute)
    # and hasn't been used yet. This is a simple way to ensure it's "new".
    # In a real app, we might use a flash or session variable.
    return if @key.created_at > 1.minute.ago

    redirect_to admin_api_keys_path, alert: "API keys can only be viewed immediately after creation."
  end

  def destroy
    @key = AdminAPIKey.find_by_uuid!(params[:id])
    @key.destroy
    redirect_to admin_api_keys_path, notice: "Admin API Key has been deleted."
  end

  private

  def admin_required
    return if current_user&.admin?

    redirect_to root_path, alert: "You must be an admin to manage Admin API Keys."
  end

end

# frozen_string_literal: true

module AdminAPI
  class UsersController < BaseController

    before_action :find_user, only: [:show, :update, :destroy]

    # GET /api/v2/admin/users
    def index
      users = User.order(:email_address)
      result = paginate(users)

      render_success(
        users: result[:items].map { |u| user_json(u) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/users/:id
    def show
      render_success(user: user_json(@user, include_details: true))
    end

    # POST /api/v2/admin/users
    def create
      user = User.new(user_params)
      user.password = params[:password] if params[:password].present?
      user.save!
      render_created(user: user_json(user))
    end

    # PATCH /api/v2/admin/users/:id
    def update
      @user.assign_attributes(user_params)
      @user.password = params[:password] if params[:password].present?
      @user.save!
      render_success(user: user_json(@user))
    end

    # DELETE /api/v2/admin/users/:id
    def destroy
      @user.destroy!
      render_deleted
    end

    private

    def find_user
      @user = User.find_by!(uuid: params[:id]) rescue User.find_by!(email_address: params[:id])
    end

    def user_params
      params.permit(:first_name, :last_name, :email_address, :time_zone, :admin)
    end

    def user_json(user, include_details: false)
      json = {
        id: user.id,
        uuid: user.uuid,
        email_address: user.email_address,
        first_name: user.first_name,
        last_name: user.last_name,
        name: user.name,
        admin: user.admin?,
        time_zone: user.time_zone,
        created_at: user.created_at&.iso8601,
        updated_at: user.updated_at&.iso8601
      }

      if include_details
        json[:organizations] = user.organizations.present.map do |org|
          ou = user.organization_users.find_by(organization: org)
          {
            id: org.id,
            uuid: org.uuid,
            name: org.name,
            permalink: org.permalink,
            admin: ou&.admin,
            all_servers: ou&.all_servers
          }
        end
      end

      json
    end

  end
end

# frozen_string_literal: true

module AdminAPI
  class OrganizationUsersController < BaseController

    before_action :find_organization
    before_action :find_organization_user, only: [:show, :update, :destroy]

    # GET /api/v2/admin/organizations/:organization_id/users
    def index
      organization_users = @organization.organization_users.includes(:user)
      result = paginate(organization_users)

      render_success(
        users: result[:items].map { |ou| organization_user_json(ou) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/organizations/:organization_id/users/:id
    def show
      render_success(user: organization_user_json(@organization_user))
    end

    # POST /api/v2/admin/organizations/:organization_id/users
    def add
      user = User.find_by!(email_address: params[:email])

      organization_user = @organization.organization_users.build(
        user: user,
        admin: params[:admin] || false,
        all_servers: params[:all_servers] || false
      )
      organization_user.save!

      render_created(user: organization_user_json(organization_user))
    end

    # PATCH /api/v2/admin/organizations/:organization_id/users/:id
    def update
      @organization_user.update!(organization_user_params)
      render_success(user: organization_user_json(@organization_user))
    end

    # DELETE /api/v2/admin/organizations/:organization_id/users/:id
    def destroy
      @organization_user.destroy!
      render_deleted
    end

    private

    def find_organization
      @organization = Organization.present.find_by!(permalink: params[:organization_id])
    end

    def find_organization_user
      @organization_user = @organization.organization_users
                                        .joins(:user)
                                        .find_by!(users: { uuid: params[:id] })
    rescue ActiveRecord::RecordNotFound
      @organization_user = @organization.organization_users
                                        .joins(:user)
                                        .find_by!(users: { email_address: params[:id] })
    end

    def organization_user_params
      params.permit(:admin, :all_servers)
    end

    def organization_user_json(organization_user)
      user = organization_user.user
      {
        id: user.id,
        uuid: user.uuid,
        email_address: user.email_address,
        name: user.name,
        admin: organization_user.admin,
        all_servers: organization_user.all_servers,
        created_at: organization_user.created_at&.iso8601
      }
    end

  end
end

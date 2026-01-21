# frozen_string_literal: true

module AdminAPI
  class OrganizationsController < BaseController

    before_action :find_organization, only: [:show, :update, :destroy]

    # GET /api/v2/admin/organizations
    def index
      organizations = Organization.present.order(:name)
      result = paginate(organizations)

      render_success(
        organizations: result[:items].map { |o| organization_json(o) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/organizations/:permalink
    def show
      render_success(organization: organization_json(@organization, include_details: true))
    end

    # POST /api/v2/admin/organizations
    def create
      organization = Organization.new(organization_params)

      if params[:owner_email].present?
        owner = User.find_by!(email_address: params[:owner_email])
        organization.owner = owner
      end

      organization.save!

      # Add owner as admin if specified
      if organization.owner.present?
        organization.organization_users.create!(
          user: organization.owner,
          admin: true,
          all_servers: true
        )
      end

      render_created(organization: organization_json(organization))
    end

    # PATCH /api/v2/admin/organizations/:permalink
    def update
      @organization.update!(organization_params)
      render_success(organization: organization_json(@organization))
    end

    # DELETE /api/v2/admin/organizations/:permalink
    def destroy
      @organization.soft_destroy
      render_deleted
    end

    private

    def find_organization
      @organization = Organization.present.find_by!(permalink: params[:id])
    end

    def organization_params
      params.permit(:name, :permalink, :time_zone)
    end

    def organization_json(organization, include_details: false)
      json = {
        id: organization.id,
        uuid: organization.uuid,
        name: organization.name,
        permalink: organization.permalink,
        time_zone: organization.time_zone,
        created_at: organization.created_at&.iso8601,
        updated_at: organization.updated_at&.iso8601
      }

      if include_details
        json[:servers] = organization.servers.present.map do |server|
          {
            id: server.id,
            uuid: server.uuid,
            name: server.name,
            permalink: server.permalink,
            mode: server.mode
          }
        end

        json[:users] = organization.organization_users.includes(:user).map do |ou|
          {
            email: ou.user.email_address,
            name: ou.user.name,
            admin: ou.admin,
            all_servers: ou.all_servers
          }
        end

        json[:ip_pools] = organization.ip_pools.map do |pool|
          {
            id: pool.id,
            uuid: pool.uuid,
            name: pool.name
          }
        end
      end

      json
    end

  end
end

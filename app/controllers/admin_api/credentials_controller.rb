# frozen_string_literal: true

module AdminAPI
  class CredentialsController < BaseController

    before_action :find_organization
    before_action :find_server
    before_action :find_credential, only: [:show, :update, :destroy]

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/credentials
    def index
      credentials = @server.credentials.order(:name)
      result = paginate(credentials)

      render_success(
        credentials: result[:items].map { |c| credential_json(c) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/credentials/:id
    def show
      render_success(credential: credential_json(@credential, include_key: true))
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/credentials
    def create
      credential = @server.credentials.build(credential_params)
      credential.save!
      render_created(credential: credential_json(credential, include_key: true))
    end

    # PATCH /api/v2/admin/organizations/:organization_id/servers/:server_id/credentials/:id
    def update
      @credential.update!(credential_update_params)
      render_success(credential: credential_json(@credential))
    end

    # DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/credentials/:id
    def destroy
      @credential.destroy!
      render_deleted
    end

    private

    def find_organization
      @organization = Organization.present.find_by!(permalink: params[:organization_id])
    end

    def find_server
      @server = @organization.servers.present.find_by!(permalink: params[:server_id])
    end

    def find_credential
      @credential = @server.credentials.find_by!(uuid: params[:id])
    end

    def credential_params
      params.permit(:name, :type, :key, :hold)
    end

    def credential_update_params
      params.permit(:name, :hold)
    end

    def credential_json(credential, include_key: false)
      json = {
        id: credential.id,
        uuid: credential.uuid,
        name: credential.name,
        type: credential.type,
        hold: credential.hold,
        last_used_at: credential.last_used_at&.iso8601,
        usage_type: credential.usage_type,
        created_at: credential.created_at&.iso8601,
        updated_at: credential.updated_at&.iso8601
      }

      if include_key
        json[:key] = credential.key
        if credential.type == "SMTP"
          json[:smtp_username] = credential.key
          json[:smtp_password] = credential.key
        end
      end

      json
    end

  end
end

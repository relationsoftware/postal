# frozen_string_literal: true

module AdminAPI
  class ServersController < BaseController

    before_action :find_organization
    before_action :find_server, only: [:show, :update, :destroy, :suspend, :unsuspend]

    # GET /api/v2/admin/organizations/:organization_id/servers
    def index
      servers = @organization.servers.present.order(:name)
      result = paginate(servers)

      render_success(
        servers: result[:items].map { |s| server_json(s) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/organizations/:organization_id/servers/:permalink
    def show
      render_success(server: server_json(@server, include_details: true))
    end

    # POST /api/v2/admin/organizations/:organization_id/servers
    def create
      server = @organization.servers.build(server_params)
      server.save!
      render_created(server: server_json(server))
    end

    # PATCH /api/v2/admin/organizations/:organization_id/servers/:permalink
    def update
      @server.update!(server_params)
      render_success(server: server_json(@server))
    end

    # DELETE /api/v2/admin/organizations/:organization_id/servers/:permalink
    def destroy
      @server.soft_destroy
      render_deleted
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:permalink/suspend
    def suspend
      @server.suspend(params[:reason] || "Suspended via Admin API")
      render_success(server: server_json(@server))
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:permalink/unsuspend
    def unsuspend
      @server.unsuspend
      render_success(server: server_json(@server))
    end

    private

    def find_organization
      @organization = Organization.present.find_by!(permalink: params[:organization_id])
    end

    def find_server
      @server = @organization.servers.present.find_by!(permalink: params[:id])
    end

    def server_params
      params.permit(
        :name, :permalink, :mode,
        :send_limit, :allow_sender,
        :log_smtp_data, :outbound_spam_threshold,
        :message_retention_days, :raw_message_retention_days, :raw_message_retention_size,
        :spam_threshold, :spam_failure_threshold,
        :postmaster_address, :privacy_mode,
        :priority
      )
    end

    def server_json(server, include_details: false)
      json = {
        id: server.id,
        uuid: server.uuid,
        name: server.name,
        permalink: server.permalink,
        mode: server.mode,
        suspended: server.suspended?,
        suspension_reason: server.suspension_reason,
        send_limit: server.send_limit,
        allow_sender: server.allow_sender,
        created_at: server.created_at&.iso8601,
        updated_at: server.updated_at&.iso8601
      }

      if include_details
        json[:domains] = server.domains.map do |domain|
          {
            id: domain.id,
            uuid: domain.uuid,
            name: domain.name,
            verified: domain.verified?
          }
        end

        json[:credentials] = server.credentials.map do |cred|
          {
            id: cred.id,
            uuid: cred.uuid,
            name: cred.name,
            type: cred.type,
            key: cred.type == "SMTP-IP" ? cred.key : nil,
            hold: cred.hold
          }
        end

        json[:routes] = server.routes.map do |route|
          {
            id: route.id,
            uuid: route.uuid,
            name: route.name,
            endpoint_type: route.endpoint_type,
            mode: route.mode
          }
        end

        json[:webhooks] = server.webhooks.map do |webhook|
          {
            id: webhook.id,
            uuid: webhook.uuid,
            name: webhook.name,
            url: webhook.url,
            enabled: webhook.enabled
          }
        end

        json[:statistics] = {
          outbound_spam_threshold: server.outbound_spam_threshold,
          message_retention_days: server.message_retention_days,
          raw_message_retention_days: server.raw_message_retention_days
        }
      end

      json
    end

  end
end

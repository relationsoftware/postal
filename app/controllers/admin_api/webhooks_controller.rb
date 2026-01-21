# frozen_string_literal: true

module AdminAPI
  class WebhooksController < BaseController

    before_action :find_organization
    before_action :find_server
    before_action :find_webhook, only: [:show, :update, :destroy, :enable, :disable]

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/webhooks
    def index
      webhooks = @server.webhooks.order(:name)
      result = paginate(webhooks)

      render_success(
        webhooks: result[:items].map { |w| webhook_json(w) },
        pagination: result[:pagination]
      )
    end

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/webhooks/:id
    def show
      render_success(webhook: webhook_json(@webhook, include_details: true))
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/webhooks
    def create
      webhook = @server.webhooks.build(webhook_params)
      webhook.save!
      render_created(webhook: webhook_json(webhook))
    end

    # PATCH /api/v2/admin/organizations/:organization_id/servers/:server_id/webhooks/:id
    def update
      @webhook.update!(webhook_params)
      render_success(webhook: webhook_json(@webhook))
    end

    # DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/webhooks/:id
    def destroy
      @webhook.destroy!
      render_deleted
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/webhooks/:id/enable
    def enable
      @webhook.update!(enabled: true)
      render_success(webhook: webhook_json(@webhook))
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/webhooks/:id/disable
    def disable
      @webhook.update!(enabled: false)
      render_success(webhook: webhook_json(@webhook))
    end

    private

    def find_organization
      @organization = Organization.present.find_by!(permalink: params[:organization_id])
    end

    def find_server
      @server = @organization.servers.present.find_by!(permalink: params[:server_id])
    end

    def find_webhook
      @webhook = @server.webhooks.find_by!(uuid: params[:id])
    end

    def webhook_params
      params.permit(:name, :url, :enabled, :sign, :all_events, events: [])
    end

    def webhook_json(webhook, include_details: false)
      json = {
        id: webhook.id,
        uuid: webhook.uuid,
        name: webhook.name,
        url: webhook.url,
        enabled: webhook.enabled,
        sign: webhook.sign,
        all_events: webhook.all_events,
        created_at: webhook.created_at&.iso8601,
        updated_at: webhook.updated_at&.iso8601
      }

      if include_details
        json[:events] = webhook.events
        json[:last_used_at] = webhook.last_used_at&.iso8601
      end

      json
    end

  end
end

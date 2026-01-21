# frozen_string_literal: true

module AdminAPI
  class MessagesController < BaseController

    before_action :find_organization
    before_action :find_server
    before_action :find_message, only: [:show, :retry, :cancel_hold, :remove_from_queue]

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/messages
    def index
      scope = params[:scope] || "all"
      status = params[:status]

      messages = case scope
                 when "incoming"
                   @server.message_db.messages(scope: "incoming", **message_query_params)
                 when "outgoing"
                   @server.message_db.messages(scope: "outgoing", **message_query_params)
                 when "held"
                   @server.message_db.messages(where: { status: "Held" }, **message_query_params)
                 else
                   @server.message_db.messages(**message_query_params)
                 end

      render_success(
        messages: messages.map { |m| message_json(m) },
        pagination: {
          page: params[:page]&.to_i || 1,
          per_page: params[:per_page]&.to_i || 25
        }
      )
    end

    # GET /api/v2/admin/organizations/:organization_id/servers/:server_id/messages/:id
    def show
      render_success(message: message_json(@message, include_details: true))
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/messages/:id/retry
    def retry
      if @message.queued_message
        @message.queued_message.retry_now
        render_success(message: message_json(@message), retried: true)
      else
        render_error "CannotRetry", message: "Message is not in queue", status: 422
      end
    end

    # POST /api/v2/admin/organizations/:organization_id/servers/:server_id/messages/:id/cancel_hold
    def cancel_hold
      if @message.status == "Held"
        @message.cancel_hold
        render_success(message: message_json(@message), hold_cancelled: true)
      else
        render_error "NotHeld", message: "Message is not held", status: 422
      end
    end

    # DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/messages/:id/queue
    def remove_from_queue
      if @message.queued_message
        @message.queued_message.destroy
        render_success(removed: true)
      else
        render_error "NotQueued", message: "Message is not in queue", status: 422
      end
    end

    private

    def find_organization
      @organization = Organization.present.find_by!(permalink: params[:organization_id])
    end

    def find_server
      @server = @organization.servers.present.find_by!(permalink: params[:server_id])
    end

    def find_message
      @message = @server.message_db.message(params[:id])
      raise ActiveRecord::RecordNotFound unless @message
    end

    def message_query_params
      {
        order: params[:order] || "timestamp",
        direction: params[:direction] || "desc",
        limit: [params[:per_page]&.to_i || 25, 100].min,
        offset: ((params[:page]&.to_i || 1) - 1) * (params[:per_page]&.to_i || 25)
      }
    end

    def message_json(message, include_details: false)
      json = {
        id: message.id,
        token: message.token,
        scope: message.scope,
        status: message.status,
        mail_from: message.mail_from,
        rcpt_to: message.rcpt_to,
        subject: message.subject,
        timestamp: message.timestamp ? Time.at(message.timestamp).iso8601 : nil,
        created_at: message.created_at ? Time.at(message.created_at).iso8601 : nil
      }

      if include_details
        json[:message_id] = message.message_id
        json[:spam_score] = message.spam_score
        json[:inspected] = message.inspected
        json[:threat] = message.threat
        json[:threat_details] = message.threat_details
        json[:bounce] = message.bounce
        json[:size] = message.size

        if message.queued_message
          json[:queued] = {
            retry_after: message.queued_message.retry_after&.iso8601,
            attempts: message.queued_message.attempts,
            ip_address: message.queued_message.ip_address
          }
        end

        json[:deliveries] = message.deliveries.map do |d|
          {
            id: d["id"],
            status: d["status"],
            details: d["details"],
            output: d["output"],
            timestamp: d["timestamp"] ? Time.at(d["timestamp"]).iso8601 : nil
          }
        end
      end

      json
    end

  end
end

# frozen_string_literal: true

module AdminAPI
  # Resolve a server by its permalink WITHOUT knowing its organisation up
  # front. An external integration can map a tenant slug (== server
  # permalink, immutable + globally unique) to the Postal
  # organisation so it can address the org-nested admin routes.
  #
  # GET /api/v2/admin/servers/find/:permalink
  class ServerLookupsController < BaseController

    def show
      server = Server.present.find_by(permalink: params[:permalink])
      return render_error("NotFound", message: "Server not found", status: 404) if server.nil?

      render_success(
        server: {
          id: server.id,
          uuid: server.uuid,
          name: server.name,
          permalink: server.permalink,
          mode: server.mode,
          suspended: server.suspended?
        },
        organization: {
          permalink: server.organization.permalink,
          name: server.organization.name
        }
      )
    end

  end
end

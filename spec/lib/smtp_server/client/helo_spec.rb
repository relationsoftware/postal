# frozen_string_literal: true

require "rails_helper"

module SMTPServer

  describe Client do
    let(:ip_address) { "1.2.3.4" }
    subject(:client) { described_class.new(ip_address) }

    describe "HELO" do
      it "returns the hostname" do
        expect(client.state).to eq :welcome
        expect(client.handle("HELO: test.example.com")).to eq "250 #{Postal::Config.postal.smtp_hostname}"
        expect(client.state).to eq :welcomed
      end
    end

    describe "EHLO" do
      it "advertises AUTH (PLAIN/LOGIN, no CRAM-MD5) when TLS is disabled" do
        # No TLS configured → no STARTTLS to gate on, so AUTH is offered as-is.
        expect(client.handle("EHLO test.example.com")).to eq ["250-My capabilities are",
                                                              "250 AUTH PLAIN LOGIN",]
      end

      context "when TLS is enabled but the session is not yet upgraded" do
        it "offers STARTTLS and withholds AUTH until the session is TLS-protected" do
          allow(Postal::Config.smtp_server).to receive(:tls_enabled?).and_return(true)
          # STARTTLS is the last (and only) capability here, so it must be the
          # space-terminated final line — a dash here would hang clients.
          expect(client.handle("EHLO test.example.com")).to eq ["250-My capabilities are",
                                                                "250 STARTTLS",]
        end
      end

      context "when the session is already TLS-protected" do
        it "advertises AUTH (PLAIN/LOGIN, no CRAM-MD5) and no STARTTLS" do
          allow(Postal::Config.smtp_server).to receive(:tls_enabled?).and_return(true)
          client.instance_variable_set(:@tls, true)
          expect(client.handle("EHLO test.example.com")).to eq ["250-My capabilities are",
                                                                "250 AUTH PLAIN LOGIN",]
        end
      end

      # Framing invariant: a multiline EHLO reply must end with a space-separated
      # final line ("250 ") and every preceding line must use the "250-"
      # continuation prefix. A dash-terminated reply hangs standard clients
      # (smtplib, PHPMailer) waiting for more lines.
      [
        { tls_enabled: false, tls_upgraded: false },
        { tls_enabled: true,  tls_upgraded: false },
        { tls_enabled: true,  tls_upgraded: true },
      ].each do |scenario|
        it "terminates the EHLO reply with a space-separated line (tls_enabled=#{scenario[:tls_enabled]}, upgraded=#{scenario[:tls_upgraded]})" do
          allow(Postal::Config.smtp_server).to receive(:tls_enabled?).and_return(scenario[:tls_enabled])
          client.instance_variable_set(:@tls, true) if scenario[:tls_upgraded]
          reply = client.handle("EHLO test.example.com")
          expect(reply.last).to start_with("250 ")
          expect(reply[0...-1]).to all(start_with("250-"))
        end
      end
    end
  end

end

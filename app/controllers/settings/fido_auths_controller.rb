# frozen_string_literal: true

class Settings::FidoAuthsController < ApplicationController
  layout 'admin'

  before_action :authenticate_user!

  def new
    u2f ||= U2F::U2F.new("#{Rails.configuration.x.local_domain}")

    # Generate one for each version of U2F, currently only `U2F_V2`
    @registration_requests = u2f.registration_requests

    # Store challenges. We need them for the verification step
    session[:challenges] = @registration_requests.map(&:challenge)

    # Fetch existing Registrations from your db and generate SignRequests
    @sign_requests = u2f.authentication_requests(SecureRandom.hex(16))

  end

end
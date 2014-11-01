class Api::QrCodesController < ApplicationController
  def new
    data = params[:d]
    resolution = params[:r] || 150
    version = params[:v]
    level = params[:l]


    # determine max data:
    # RQRCode::QRCode.count_max_data_bits(RQRCode::QRRSBlock.get_rs_blocks(version, RQRCode::QRERRORCORRECTLEVEL[level]))

    if !version || !level
      # if no version and level, auto determine both
      # use the lowest possible from our max array
      version ||= 1
      level ||= :h
      version = version.to_i
      level = level.to_sym
      begin
        qr = RQRCode::QRCode.new(data, :size => version, :level => level)
        Rails.logger.info "version = #{version}, level = #{level}"
      rescue RQRCode::QRCodeRunTimeError => e
        # keep retrying until we are at 14
        Rails.logger.info "Caught error: version = #{version}, level = #{level}. #{e.message}"
        if version < 14
          version = version + 1
          retry
        end
      end
    else
      version = version.to_i
      level = level.to_sym
      Rails.logger.info "version = #{version}, level = #{level}"
      qr = RQRCode::QRCode.new(data, :size => version, :level => level)
    end

    png = qr.to_img

    resolution = resolution.to_i
    send_data(png.resize(resolution, resolution), :type => 'image/png', :disposition => 'inline')
  end
end

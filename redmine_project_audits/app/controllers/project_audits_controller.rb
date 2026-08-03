class ProjectAuditsController < ApplicationController
  # Usamos el diseño del panel de administración
  layout 'admin'

  # Bloqueamos el acceso para que solo los administradores puedan entrar
  before_action :require_admin

  def index
    @from_date = params[:from_date]
    @to_date   = params[:to_date]

    # Carga base de auditorías optimizando la consulta de usuarios
    @audits = ProjectAudit.includes(:user).order(created_at: :desc)

    # Aplicamos filtro de fecha 'Desde' (inicio del día)
    if @from_date.present?
      @audits = @audits.where("created_at >= ?", Time.zone.parse(@from_date).beginning_of_day)
    end

    # Aplicamos filtro de fecha 'Hasta' (fin del día)
    if @to_date.present?
      @audits = @audits.where("created_at <= ?", Time.zone.parse(@to_date).end_of_day)
    end

    # Si no se aplicó ningún filtro de fecha, mantenemos el límite de 100 registros por rendimiento
    unless @from_date.present? || @to_date.present?
      @audits = @audits.limit(100)
    end
  end
end

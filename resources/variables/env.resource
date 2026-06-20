*** Variables ***
# ─── URLs base ───────────────────────────────────────────────────────────────
# Puerto del Gateway: valor de PORT en tu .env (main.ts default = 3002)
# Si usas otro puerto, cambia solo este valor.
${GATEWAY_URL}          http://localhost:3002/api/v1
${ENTIDADES_URL}        http://localhost:3001/api/v1
${AGENDA_URL}           http://localhost:3003/api/v1
${MULTISUCURSAL_URL}    http://localhost:3004/api/v1
${REPORTES_URL}         http://localhost:3006/api/v1
${INVENTARIO_URL}       http://localhost:3007/api/v1
${INTEGRACIONES_URL}    http://localhost:3009/api/v1

# ─── Rutas del Gateway (pathPrefix exacto del seed.js) ───────────────────────
# El gateway enruta por el primer segmento de la URL directamente:
# GET /pacientes/1 → proxy a MS_Entidades /api/v1/pacientes/1
${ROUTE_CLIENTES}       /clientes
${ROUTE_PACIENTES}      /pacientes
${ROUTE_USUARIOS}       /usuarios
${ROUTE_SUCURSALES}     /sucursales
${ROUTE_ROLES}          /roles
${ROUTE_PERMISOS}       /permisos
${ROUTE_CITAS}          /citas
${ROUTE_RECORDATORIOS}  /recordatorios
${ROUTE_SALA_ESPERA}    /sala-espera
${ROUTE_ASIGNACIONES}   /asignaciones
${ROUTE_PRODUCTOS}      /productos
${ROUTE_CATEGORIAS}     /categorias
${ROUTE_MOVIMIENTOS}    /movimientos-stock
${ROUTE_UPLOADS}        /uploads
${ROUTE_REPORTES}       /reportes
${ROUTE_INTEGRACIONES}  /integraciones

# ─── Credenciales del usuario administrador de pruebas ───────────────────────
${ADMIN_EMAIL}          admin.rf@clinicore.qa
${ADMIN_PASSWORD}       Admin123!

# ─── Configuración HTTP global ───────────────────────────────────────────────
${TIMEOUT}              10s
${CONTENT_TYPE}         application/json

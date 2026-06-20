*** Settings ***
Documentation     Suite de pruebas de integración End-to-End de CliniCore.
...               Simula el flujo completo de trabajo de una clínica veterinaria:
...               1. Registrar un cliente (dueño de mascota)
...               2. Registrar un paciente (mascota) asociado al cliente
...               3. Agendar una cita para el paciente
...               4. Consultar la cita por pacienteId
...               5. Registrar un producto en inventario
...               6. Limpiar todos los datos de prueba
...
...               Este flujo valida que todos los microservicios se comunican
...               correctamente a través del API Gateway.

Library           RequestsLibrary
Library           Collections
Library           DateTime
Resource          ../../resources/variables/env.resource
Resource          ../../resources/keywords/auth_keywords.resource
Resource          ../../resources/keywords/api_keywords.resource
Resource          ../../resources/keywords/common_keywords.resource

Suite Setup       Suite Setup Con Autenticacion
Suite Teardown    Delete All Sessions

*** Variables ***
${EP_CLIENTES}      ${ROUTE_CLIENTES}
${EP_PACIENTES}     ${ROUTE_PACIENTES}
${EP_CITAS}         ${ROUTE_CITAS}
${EP_PRODUCTOS}     ${ROUTE_PRODUCTOS}
${E2E_CLIENTE_ID}   ${NONE}
${E2E_PACIENTE_ID}  ${NONE}
${E2E_CITA_ID}      ${NONE}
${E2E_PRODUCTO_ID}  ${NONE}

*** Test Cases ***

TC-E2E-001: Registrar Nuevo Dueno De Mascota
    [Documentation]    PASO 1 — El recepcionista registra al dueño (cliente) en el sistema.
    [Tags]    e2e    integracion    flujo-completo
    ${email}=    Generar Email Unico
    ${doc}=      Generar Documento Unico
    ${body}=    Create Dictionary
    ...    nombres=María Fernanda López Rodríguez
    ...    email=${email}
    ...    celular=3201234567
    ...    direccion=Carrera 15 # 93-47 Apto 201
    ...    ciudad=Bogotá
    ...    documento=${doc}
    ${resp}=    POST Con Auth    ${EP_CLIENTES}    ${body}
    Status Should Be    201    ${resp}
    ${id}=    Obtener ID De Respuesta    ${resp}
    Set Suite Variable    ${E2E_CLIENTE_ID}    ${id}
    Log    [E2E PASO 1] ✔ Cliente registrado — ID: ${id}

TC-E2E-002: Registrar Mascota Del Cliente
    [Documentation]    PASO 2 — Se registra la mascota asociada al cliente del paso 1.
    [Tags]    e2e    integracion    flujo-completo
    Skip If    '${E2E_CLIENTE_ID}' == 'None'    Requiere TC-E2E-001 exitoso
    ${body}=    Create Dictionary
    ...    nombre=Luna E2E
    ...    edad=2 años
    ...    sexo=Hembra
    ...    especie=Felino
    ...    raza=Persa
    ...    peso=4 kg
    ...    castrado=${TRUE}
    ...    fechaIngreso=2026-06-20
    ...    alimentoPrincipal=Pienso húmedo premium
    ...    clienteId=${E2E_CLIENTE_ID}
    ...    sedeId=${1}
    ${resp}=    POST Con Auth    ${EP_PACIENTES}    ${body}
    Status Should Be    201    ${resp}
    ${id}=    Obtener ID De Respuesta    ${resp}
    Set Suite Variable    ${E2E_PACIENTE_ID}    ${id}
    # Verificar vínculo cliente-paciente
    ${cliente_id}=    Get From Dictionary    ${resp.json()}    clienteId
    Should Be Equal As Numbers    ${cliente_id}    ${E2E_CLIENTE_ID}
    Log    [E2E PASO 2] ✔ Paciente registrado — ID: ${id} | clienteId: ${E2E_CLIENTE_ID}

TC-E2E-003: Agendar Cita Para La Mascota
    [Documentation]    PASO 3 — El recepcionista agenda una cita para la mascota.
    [Tags]    e2e    integracion    flujo-completo
    Skip If    '${E2E_PACIENTE_ID}' == 'None'    Requiere TC-E2E-002 exitoso
    ${body}=    Create Dictionary
    ...    fecha=2026-07-15T11:00:00.000Z
    ...    motivo=Primera consulta de control post-adopción
    ...    tipo=Consulta
    ...    pacienteId=${E2E_PACIENTE_ID}
    ${resp}=    POST Con Auth    ${EP_CITAS}    ${body}
    Status Should Be    201    ${resp}
    ${id}=    Obtener ID De Respuesta    ${resp}
    Set Suite Variable    ${E2E_CITA_ID}    ${id}
    ${pac_id}=    Get From Dictionary    ${resp.json()}    pacienteId
    Should Be Equal As Numbers    ${pac_id}    ${E2E_PACIENTE_ID}
    Log    [E2E PASO 3] ✔ Cita agendada — ID: ${id} | pacienteId: ${E2E_PACIENTE_ID}

TC-E2E-004: Consultar Agenda Del Paciente
    [Documentation]    PASO 4 — Se recuperan todas las citas de la mascota por filtro.
    [Tags]    e2e    integracion    flujo-completo
    Skip If    '${E2E_PACIENTE_ID}' == 'None'    Requiere TC-E2E-002 exitoso
    ${params}=    Create Dictionary    pacienteId=${E2E_PACIENTE_ID}
    ${resp}=    GET On Session    gateway    ${EP_CITAS}    params=${params}
    Status Should Be    200    ${resp}
    ${citas}=    Set Variable    ${resp.json()}
    Should Be True    ${citas.__len__()} >= 1
    ...    msg=Debe existir al menos la cita recién creada
    ${primera_cita_id}=    Get From Dictionary    ${citas[0]}    id
    Should Be Equal As Numbers    ${primera_cita_id}    ${E2E_CITA_ID}
    Log    [E2E PASO 4] ✔ Agenda consultada — ${citas.__len__()} cita(s) para paciente ${E2E_PACIENTE_ID}

TC-E2E-005: Registrar Producto En Inventario Para La Cita
    [Documentation]    PASO 5 — El veterinario registra la vacuna que se usará en la consulta.
    [Tags]    e2e    integracion    flujo-completo
    ${ts}=    Generar Documento Unico
    ${body}=    Create Dictionary
    ...    nombre=Vacuna Triple Felina E2E-${ts}
    ...    descripcion=Vacuna para la cita E2E de Luna
    ...    marca=VetProtect
    ...    precioVenta=65000
    ...    cantidadActual=${30}
    ...    cantidadMinima=${5}
    ${resp}=    POST Con Auth    ${EP_PRODUCTOS}    ${body}
    Status Should Be    201    ${resp}
    ${id}=    Obtener ID De Respuesta    ${resp}
    Set Suite Variable    ${E2E_PRODUCTO_ID}    ${id}
    Log    [E2E PASO 5] ✔ Producto registrado — ID: ${id}

TC-E2E-006: Verificar Consistencia De Datos Entre Servicios
    [Documentation]    PASO 6 — Valida que todos los registros creados son consistentes
    ...                entre microservicios consultando cada uno por separado.
    [Tags]    e2e    integracion    flujo-completo    consistency
    Skip If    '${E2E_CLIENTE_ID}' == 'None'    Requiere pasos anteriores
    # Verificar cliente en MS_Entidades
    ${resp_cli}=    GET Con Auth    ${EP_CLIENTES}/${E2E_CLIENTE_ID}
    Status Should Be    200    ${resp_cli}
    # Verificar paciente en MS_Entidades
    ${resp_pac}=    GET Con Auth    ${EP_PACIENTES}/${E2E_PACIENTE_ID}
    Status Should Be    200    ${resp_pac}
    ${cli_en_pac}=    Get From Dictionary    ${resp_pac.json()}    clienteId
    Should Be Equal As Numbers    ${cli_en_pac}    ${E2E_CLIENTE_ID}
    # Verificar cita en MS_Agenda
    ${resp_cit}=    GET Con Auth    ${EP_CITAS}/${E2E_CITA_ID}
    Status Should Be    200    ${resp_cit}
    ${pac_en_cit}=    Get From Dictionary    ${resp_cit.json()}    pacienteId
    Should Be Equal As Numbers    ${pac_en_cit}    ${E2E_PACIENTE_ID}
    # Verificar producto en MS_Inventario
    ${resp_prd}=    GET Con Auth    ${EP_PRODUCTOS}/${E2E_PRODUCTO_ID}
    Status Should Be    200    ${resp_prd}
    Log    [E2E PASO 6] ✔ Consistencia validada en todos los microservicios

TC-E2E-007: Limpiar Datos Del Flujo E2E
    [Documentation]    PASO 7 — Elimina todos los registros creados durante el flujo.
    ...                Orden inverso: Cita → Paciente → Cliente → Producto.
    [Tags]    e2e    integracion    cleanup
    Run Keyword If    '${E2E_CITA_ID}' != 'None'
    ...    DELETE Con Auth    ${EP_CITAS}/${E2E_CITA_ID}
    Run Keyword If    '${E2E_PACIENTE_ID}' != 'None'
    ...    DELETE Con Auth    ${EP_PACIENTES}/${E2E_PACIENTE_ID}
    Run Keyword If    '${E2E_CLIENTE_ID}' != 'None'
    ...    DELETE Con Auth    ${EP_CLIENTES}/${E2E_CLIENTE_ID}
    Run Keyword If    '${E2E_PRODUCTO_ID}' != 'None'
    ...    DELETE Con Auth    ${EP_PRODUCTOS}/${E2E_PRODUCTO_ID}
    Log    [E2E PASO 7] ✔ Todos los datos de prueba eliminados

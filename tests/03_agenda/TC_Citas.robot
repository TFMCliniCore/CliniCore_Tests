*** Settings ***
Documentation     Suite de pruebas CRUD + filtros para Citas (MS_Agenda).
...               El setup crea la cadena completa: Cliente → Paciente → Citas.
...               Prueba CRUD y los query params: desde, hasta, estado, tipo, pacienteId.

Library           RequestsLibrary
Library           Collections
Library           String
Resource          ../../resources/variables/env.resource
Resource          ../../resources/variables/testdata.resource
Resource          ../../resources/keywords/auth_keywords.resource
Resource          ../../resources/keywords/api_keywords.resource
Resource          ../../resources/keywords/common_keywords.resource

Suite Setup       Inicializar Suite Citas
Suite Teardown    Limpiar Suite Citas

*** Variables ***
${EP_CLIENTES}          ${ROUTE_CLIENTES}
${EP_PACIENTES}         ${ROUTE_PACIENTES}
${EP_CITAS}             ${ROUTE_CITAS}
${ID_CLIENTE_CITAS}     ${NONE}
${ID_PACIENTE_CITAS}    ${NONE}
${ID_CITA}              ${NONE}
${SEDE_ID}              ${1}

*** Keywords ***
Inicializar Suite Citas
    Suite Setup Con Autenticacion
    # Crear cliente
    ${email}=    Generar Email Unico
    ${doc}=      Generar Documento Unico
    ${cli_body}=    Create Dictionary
    ...    nombres=Cliente Suite Citas
    ...    email=${email}
    ...    celular=3160000001
    ...    direccion=Calle Citas 100
    ...    ciudad=Cali
    ...    documento=${doc}
    ${resp_cli}=    POST Con Auth    ${EP_CLIENTES}    ${cli_body}
    ${id_cli}=    Obtener ID De Respuesta    ${resp_cli}
    Set Suite Variable    ${ID_CLIENTE_CITAS}    ${id_cli}
    # Crear paciente
    ${pac_body}=    Create Dictionary
    ...    nombre=Max Agenda Robot    edad=2 años    sexo=Macho
    ...    especie=Canino    raza=Golden Retriever    peso=20 kg
    ...    castrado=${FALSE}    fechaIngreso=2026-06-20
    ...    alimentoPrincipal=Concentrado Adulto
    ...    clienteId=${id_cli}    sedeId=${SEDE_ID}
    ${resp_pac}=    POST Con Auth    ${EP_PACIENTES}    ${pac_body}
    ${id_pac}=    Obtener ID De Respuesta    ${resp_pac}
    Set Suite Variable    ${ID_PACIENTE_CITAS}    ${id_pac}
    Log    Suite Citas lista — pacienteId: ${id_pac}

Limpiar Suite Citas
    Run Keyword If    '${ID_CITA}' != 'None'
    ...    DELETE Con Auth    ${EP_CITAS}/${ID_CITA}
    Run Keyword If    '${ID_PACIENTE_CITAS}' != 'None'
    ...    DELETE Con Auth    ${EP_PACIENTES}/${ID_PACIENTE_CITAS}
    Run Keyword If    '${ID_CLIENTE_CITAS}' != 'None'
    ...    DELETE Con Auth    ${EP_CLIENTES}/${ID_CLIENTE_CITAS}
    Delete All Sessions

*** Test Cases ***

TC-CIT-001: Listar Todas Las Citas
    [Documentation]    GET /agenda/citas retorna lista (200), puede estar vacía.
    [Tags]    citas    smoke    listado
    ${resp}=    GET Con Auth    ${EP_CITAS}
    Status Should Be    200    ${resp}
    Should Be True    isinstance($resp.json(), list)
    Log    Citas en BD: ${resp.json().__len__()}

TC-CIT-002: Crear Nueva Cita
    [Documentation]    POST /agenda/citas crea una cita asociada al paciente del setup.
    [Tags]    citas    crud    positivo    setup
    ${body}=    Create Dictionary
    ...    fecha=2026-07-10T09:00:00.000Z
    ...    motivo=Vacunación antirrábica anual Robot Test
    ...    tipo=Vacunación
    ...    pacienteId=${ID_PACIENTE_CITAS}
    ${resp}=    POST Con Auth    ${EP_CITAS}    ${body}
    Status Should Be    201    ${resp}
    Verificar Estructura Base    ${resp}    id    fecha    motivo    tipo    pacienteId
    ${id}=    Obtener ID De Respuesta    ${resp}
    Set Suite Variable    ${ID_CITA}    ${id}
    Log    ✔ Cita creada con ID: ${id}

TC-CIT-003: Obtener Cita Por ID
    [Documentation]    GET /agenda/citas/:id retorna la cita correcta.
    [Tags]    citas    crud    positivo
    Skip If    '${ID_CITA}' == 'None'    Requiere TC-CIT-002 exitoso
    ${resp}=    GET Con Auth    ${EP_CITAS}/${ID_CITA}
    Status Should Be    200    ${resp}
    ${id_resp}=    Get From Dictionary    ${resp.json()}    id
    Should Be Equal As Numbers    ${id_resp}    ${ID_CITA}

TC-CIT-004: Actualizar Motivo Con PATCH
    [Documentation]    PATCH /agenda/citas/:id actualiza campos de la cita.
    [Tags]    citas    crud    positivo
    Skip If    '${ID_CITA}' == 'None'    Requiere TC-CIT-002 exitoso
    ${body}=    Create Dictionary
    ...    motivo=Seguimiento post-vacunación Robot
    ...    tipo=Seguimiento
    ${resp}=    PATCH Con Auth    ${EP_CITAS}/${ID_CITA}    ${body}
    Status Should Be    200    ${resp}
    Validar Campo    ${resp}    tipo    Seguimiento
    Log    ✔ Cita ${ID_CITA} actualizada

TC-CIT-005: Filtrar Citas Por PacienteId
    [Documentation]    GET con ?pacienteId filtra citas del paciente creado en setup.
    [Tags]    citas    filtros    positivo
    Skip If    '${ID_PACIENTE_CITAS}' == 'None'    Requiere setup exitoso
    ${params}=    Create Dictionary    pacienteId=${ID_PACIENTE_CITAS}
    ${resp}=    GET On Session    gateway    ${EP_CITAS}    params=${params}
    Status Should Be    200    ${resp}
    ${lista}=    Set Variable    ${resp.json()}
    Should Be True    isinstance($lista, list)
    FOR    ${cita}    IN    @{lista}
        ${pac_id}=    Get From Dictionary    ${cita}    pacienteId
        Should Be Equal As Numbers    ${pac_id}    ${ID_PACIENTE_CITAS}
    END
    Log    ✔ Filtro pacienteId OK — citas encontradas: ${lista.__len__()}

TC-CIT-006: Filtrar Citas Por Tipo
    [Documentation]    GET con ?tipo filtra citas por tipo de consulta.
    [Tags]    citas    filtros    positivo
    ${params}=    Create Dictionary    tipo=Seguimiento
    ${resp}=    GET On Session    gateway    ${EP_CITAS}    params=${params}
    Status Should Be    200    ${resp}
    Should Be True    isinstance($resp.json(), list)
    Log    Citas de tipo Seguimiento: ${resp.json().__len__()}

TC-CIT-007: Filtrar Citas Por Rango De Fechas
    [Documentation]    GET con ?desde y ?hasta retorna citas en el rango dado.
    [Tags]    citas    filtros    positivo
    ${params}=    Create Dictionary
    ...    desde=2026-07-01
    ...    hasta=2026-07-31
    ${resp}=    GET On Session    gateway    ${EP_CITAS}    params=${params}
    Status Should Be    200    ${resp}
    Should Be True    isinstance($resp.json(), list)
    Log    Citas en julio 2026: ${resp.json().__len__()}

TC-CIT-008: Crear Cita Sin PacienteId Retorna 400
    [Documentation]    El campo pacienteId es obligatorio; sin él retorna 400.
    [Tags]    citas    negativo    validacion
    ${body}=    Create Dictionary
    ...    fecha=2026-08-01T10:00:00.000Z
    ...    motivo=Cita sin paciente
    ...    tipo=Consulta
    ${resp}=    POST On Session    gateway    ${EP_CITAS}
    ...    json=${body}    expected_status=400
    Status Should Be    400    ${resp}

TC-CIT-009: Obtener Cita Inexistente Retorna 404
    [Documentation]    GET con ID no existente retorna 404.
    [Tags]    citas    negativo
    ${resp}=    GET On Session    gateway    ${EP_CITAS}/999999
    ...    expected_status=404
    Status Should Be    404    ${resp}

TC-CIT-010: Eliminar Cita
    [Documentation]    DELETE /agenda/citas/:id elimina la cita de prueba.
    [Tags]    citas    crud    cleanup
    Skip If    '${ID_CITA}' == 'None'    Requiere TC-CIT-002 exitoso
    ${resp}=    DELETE Con Auth    ${EP_CITAS}/${ID_CITA}
    Should Be True    ${resp.status_code} in [200, 204]
    Set Suite Variable    ${ID_CITA}    ${NONE}
    Log    ✔ Cita eliminada

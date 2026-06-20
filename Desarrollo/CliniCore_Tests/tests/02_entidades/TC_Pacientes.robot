*** Settings ***
Documentation     Suite de pruebas CRUD para Pacientes (MS_Entidades-Core).
...               Un paciente pertenece a un cliente y a una sede.
...               El setup de suite crea un cliente y usa la sedeId=1 por defecto.

Library           RequestsLibrary
Library           Collections
Resource          ../../resources/variables/env.resource
Resource          ../../resources/variables/testdata.resource
Resource          ../../resources/keywords/auth_keywords.resource
Resource          ../../resources/keywords/api_keywords.resource
Resource          ../../resources/keywords/common_keywords.resource

Suite Setup       Inicializar Suite Pacientes
Suite Teardown    Limpiar Suite Pacientes

*** Variables ***
${EP_CLIENTES}          ${ROUTE_CLIENTES}
${EP_PACIENTES}         ${ROUTE_PACIENTES}
${ID_CLIENTE_AUX}       ${NONE}
${ID_PACIENTE}          ${NONE}
${SEDE_ID}              ${1}

*** Keywords ***
Inicializar Suite Pacientes
    Suite Setup Con Autenticacion
    # Crear cliente auxiliar para asociar pacientes
    ${email}=    Generar Email Unico
    ${doc}=      Generar Documento Unico
    ${body}=    Create Dictionary
    ...    nombres=Cliente Auxiliar Pacientes
    ...    email=${email}
    ...    celular=3150000001
    ...    direccion=Calle Auxiliar 1
    ...    ciudad=Bogotá
    ...    documento=${doc}
    ${resp}=    POST Con Auth    ${EP_CLIENTES}    ${body}
    ${id}=    Obtener ID De Respuesta    ${resp}
    Set Suite Variable    ${ID_CLIENTE_AUX}    ${id}
    Log    Suite inicializada — cliente auxiliar ID: ${id}

Limpiar Suite Pacientes
    Run Keyword If    '${ID_PACIENTE}' != 'None'
    ...    DELETE Con Auth    ${EP_PACIENTES}/${ID_PACIENTE}
    Run Keyword If    '${ID_CLIENTE_AUX}' != 'None'
    ...    DELETE Con Auth    ${EP_CLIENTES}/${ID_CLIENTE_AUX}
    Delete All Sessions

Construir Body Paciente
    [Arguments]    ${cliente_id}    ${sede_id}
    ${body}=    Copy Dictionary    ${PACIENTE_BASE}
    Set To Dictionary    ${body}    clienteId=${cliente_id}    sedeId=${sede_id}
    RETURN    ${body}

*** Test Cases ***

TC-PAC-001: Listar Todos Los Pacientes
    [Documentation]    GET /entidades/pacientes retorna lista (200).
    [Tags]    pacientes    smoke    listado
    ${resp}=    GET Con Auth    ${EP_PACIENTES}
    Status Should Be    200    ${resp}
    Should Be True    isinstance($resp.json(), list)
    Log    Pacientes en BD: ${resp.json().__len__()}

TC-PAC-002: Crear Nuevo Paciente
    [Documentation]    POST /entidades/pacientes crea un paciente con clienteId y sedeId.
    [Tags]    pacientes    crud    positivo    setup
    ${body}=    Construir Body Paciente    ${ID_CLIENTE_AUX}    ${SEDE_ID}
    ${resp}=    POST Con Auth    ${EP_PACIENTES}    ${body}
    Status Should Be    201    ${resp}
    Verificar Estructura Base    ${resp}    id    nombre    especie    clienteId
    ${id}=    Obtener ID De Respuesta    ${resp}
    Set Suite Variable    ${ID_PACIENTE}    ${id}
    Log    ✔ Paciente creado con ID: ${id}

TC-PAC-003: Obtener Paciente Por ID
    [Documentation]    GET /entidades/pacientes/:id retorna datos del paciente.
    [Tags]    pacientes    crud    positivo
    Skip If    '${ID_PACIENTE}' == 'None'    Requiere TC-PAC-002 exitoso
    ${resp}=    GET Con Auth    ${EP_PACIENTES}/${ID_PACIENTE}
    Status Should Be    200    ${resp}
    ${id_resp}=    Get From Dictionary    ${resp.json()}    id
    Should Be Equal As Numbers    ${id_resp}    ${ID_PACIENTE}

TC-PAC-004: Actualizar Peso Y Alimento Con PATCH
    [Documentation]    PATCH actualiza campos del paciente sin reescribir todos.
    [Tags]    pacientes    crud    positivo
    Skip If    '${ID_PACIENTE}' == 'None'    Requiere TC-PAC-002 exitoso
    ${resp}=    PATCH Con Auth    ${EP_PACIENTES}/${ID_PACIENTE}    ${PACIENTE_UPDATE}
    Status Should Be    200    ${resp}
    Validar Campo    ${resp}    peso    26 kg
    Log    ✔ Paciente ${ID_PACIENTE} actualizado

TC-PAC-005: Crear Paciente Sin ClienteId Retorna Error
    [Documentation]    El sistema rechaza pacientes sin clienteId obligatorio (400).
    [Tags]    pacientes    negativo    validacion
    ${body}=    Create Dictionary
    ...    nombre=SinCliente    edad=1 año    sexo=Macho
    ...    especie=Felino    raza=Mestizo    peso=3 kg
    ...    castrado=${FALSE}    fechaIngreso=2026-06-20
    ...    alimentoPrincipal=Croquetas    sedeId=${SEDE_ID}
    ${resp}=    POST On Session    gateway    ${EP_PACIENTES}
    ...    json=${body}    expected_status=400
    Status Should Be    400    ${resp}

TC-PAC-006: Obtener Paciente Inexistente Retorna 404
    [Documentation]    GET con ID no existente debe retornar 404.
    [Tags]    pacientes    negativo
    ${resp}=    GET On Session    gateway    ${EP_PACIENTES}/999999
    ...    expected_status=404
    Status Should Be    404    ${resp}

TC-PAC-007: Eliminar Paciente
    [Documentation]    DELETE /entidades/pacientes/:id elimina el registro.
    [Tags]    pacientes    crud    cleanup
    Skip If    '${ID_PACIENTE}' == 'None'    Requiere TC-PAC-002 exitoso
    ${resp}=    DELETE Con Auth    ${EP_PACIENTES}/${ID_PACIENTE}
    Should Be True    ${resp.status_code} in [200, 204]
    Set Suite Variable    ${ID_PACIENTE}    ${NONE}
    Log    ✔ Paciente eliminado

*** Settings ***
Documentation     Suite de pruebas CRUD para el recurso Clientes (MS_Entidades-Core).
...               Prueba creación, lectura, actualización y eliminación vía API Gateway.
...               Los tests están ordenados: CREATE → READ → UPDATE → DELETE.

Library           RequestsLibrary
Library           Collections
Resource          ../../resources/variables/env.resource
Resource          ../../resources/variables/testdata.resource
Resource          ../../resources/keywords/auth_keywords.resource
Resource          ../../resources/keywords/api_keywords.resource
Resource          ../../resources/keywords/common_keywords.resource

Suite Setup       Suite Setup Con Autenticacion
Suite Teardown    Delete All Sessions

*** Variables ***
${EP_CLIENTES}          ${ROUTE_CLIENTES}
${ID_CLIENTE}           ${NONE}

*** Test Cases ***

TC-CLI-001: Listar Todos Los Clientes
    [Documentation]    GET /entidades/clientes retorna lista (200). Puede estar vacía.
    [Tags]    clientes    smoke    listado
    ${resp}=    GET Con Auth    ${EP_CLIENTES}
    Status Should Be    200    ${resp}
    ${data}=    Set Variable    ${resp.json()}
    Should Be True    isinstance($data, list)
    Log    Clientes existentes en BD: ${data.__len__()}

TC-CLI-002: Crear Nuevo Cliente
    [Documentation]    POST /entidades/clientes crea un cliente y retorna id.
    [Tags]    clientes    crud    positivo    setup
    ${email}=    Generar Email Unico
    ${doc}=      Generar Documento Unico
    ${body}=    Create Dictionary
    ...    nombres=Pedro Prueba Robot Framework
    ...    email=${email}
    ...    celular=3109876543
    ...    direccion=Av Test Automatización 456 # 78-90
    ...    ciudad=Bogotá
    ...    documento=${doc}
    ${resp}=    POST Con Auth    ${EP_CLIENTES}    ${body}
    Status Should Be    201    ${resp}
    Verificar Estructura Base    ${resp}    id    nombres    email
    ${id}=    Obtener ID De Respuesta    ${resp}
    Set Suite Variable    ${ID_CLIENTE}    ${id}
    Log    ✔ Cliente creado con ID: ${id}

TC-CLI-003: Obtener Cliente Por ID
    [Documentation]    GET /entidades/clientes/:id retorna el cliente recién creado.
    [Tags]    clientes    crud    positivo
    Skip If    '${ID_CLIENTE}' == 'None'    Requiere TC-CLI-002 exitoso
    ${resp}=    GET Con Auth    ${EP_CLIENTES}/${ID_CLIENTE}
    Status Should Be    200    ${resp}
    ${id_resp}=    Get From Dictionary    ${resp.json()}    id
    Should Be Equal As Numbers    ${id_resp}    ${ID_CLIENTE}
    Log    ✔ Cliente ${ID_CLIENTE} encontrado

TC-CLI-004: Actualizar Ciudad Y Celular Con PATCH
    [Documentation]    PATCH actualiza campos individuales sin afectar el resto.
    [Tags]    clientes    crud    positivo
    Skip If    '${ID_CLIENTE}' == 'None'    Requiere TC-CLI-002 exitoso
    ${resp}=    PATCH Con Auth    ${EP_CLIENTES}/${ID_CLIENTE}    ${CLIENTE_UPDATE}
    Status Should Be    200    ${resp}
    Validar Campo    ${resp}    ciudad    Medellín
    Log    ✔ Cliente ${ID_CLIENTE} actualizado correctamente

TC-CLI-005: Crear Cliente Con Email Duplicado Retorna Error
    [Documentation]    El sistema rechaza emails ya registrados (409 o 400).
    [Tags]    clientes    negativo    validacion
    Skip If    '${ID_CLIENTE}' == 'None'    Requiere TC-CLI-002 exitoso
    ${resp_original}=    GET Con Auth    ${EP_CLIENTES}/${ID_CLIENTE}
    ${email_existente}=    Get From Dictionary    ${resp_original.json()}    email
    ${doc_nuevo}=    Generar Documento Unico
    ${body}=    Create Dictionary
    ...    nombres=Duplicado Test
    ...    email=${email_existente}
    ...    celular=3000000000
    ...    direccion=Calle Duplicada 1
    ...    ciudad=Cali
    ...    documento=${doc_nuevo}
    ${resp}=    POST On Session    gateway    ${EP_CLIENTES}
    ...    json=${body}    expected_status=any
    Should Be True    ${resp.status_code} in [400, 409]
    ...    msg=Email duplicado debe retornar 400 o 409, obtuvo ${resp.status_code}

TC-CLI-006: Crear Cliente Sin Campos Obligatorios
    [Documentation]    POST sin campos requeridos debe retornar 400 Bad Request.
    [Tags]    clientes    negativo    validacion
    ${body}=    Create Dictionary    nombres=SoloCampoNombres
    ${resp}=    POST On Session    gateway    ${EP_CLIENTES}
    ...    json=${body}    expected_status=400
    Status Should Be    400    ${resp}

TC-CLI-007: Obtener Cliente Con ID Inexistente
    [Documentation]    GET con ID que no existe debe retornar 404.
    [Tags]    clientes    negativo
    ${resp}=    GET On Session    gateway    ${EP_CLIENTES}/999999
    ...    expected_status=404
    Status Should Be    404    ${resp}

TC-CLI-008: Eliminar Cliente
    [Documentation]    DELETE /entidades/clientes/:id elimina el cliente de prueba.
    [Tags]    clientes    crud    cleanup
    Skip If    '${ID_CLIENTE}' == 'None'    Requiere TC-CLI-002 exitoso
    ${resp}=    DELETE Con Auth    ${EP_CLIENTES}/${ID_CLIENTE}
    Should Be True    ${resp.status_code} in [200, 204]
    Log    ✔ Cliente ${ID_CLIENTE} eliminado

TC-CLI-009: Cliente Eliminado Retorna 404
    [Documentation]    Verificación post-eliminación: el recurso ya no existe.
    [Tags]    clientes    negativo    cleanup
    Skip If    '${ID_CLIENTE}' == 'None'    Requiere TC-CLI-008 exitoso
    ${resp}=    GET On Session    gateway    ${EP_CLIENTES}/${ID_CLIENTE}
    ...    expected_status=404
    Status Should Be    404    ${resp}
    Log    ✔ Confirmado: cliente ${ID_CLIENTE} ya no existe

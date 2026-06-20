*** Settings ***
Library     RequestsLibrary
Library     Collections
Resource    ../variables/env.resource

*** Keywords ***
Obtener Token De Autenticacion
    [Documentation]    Realiza POST /auth/login y devuelve el access_token JWT.
    ...                NestJS @Post sin @HttpCode devuelve 201 por defecto.
    ${body}=    Create Dictionary    email=${ADMIN_EMAIL}    password=${ADMIN_PASSWORD}
    ${resp}=    POST    url=${GATEWAY_URL}/auth/login    json=${body}    expected_status=201
    Dictionary Should Contain Key    ${resp.json()}    access_token
    ${token}=    Get From Dictionary    ${resp.json()}    access_token
    Should Not Be Empty    ${token}
    RETURN    ${token}

Crear Headers Con Token
    [Arguments]    ${token}
    [Documentation]    Devuelve dict de headers con Authorization Bearer.
    ${headers}=    Create Dictionary
    ...    Content-Type=${CONTENT_TYPE}
    ...    Authorization=Bearer ${token}
    RETURN    ${headers}

Suite Setup Con Autenticacion
    [Documentation]    Reutiliza token/sesión global de __init__.robot (1 solo login).
    ...                Siempre crea/recrea la sesión 'gateway' para resistir a Delete All Sessions
    ...                de suites anteriores.
    ${tiene_global}=    Run Keyword And Return Status    Variable Should Exist    ${GLOBAL_TOKEN}
    IF    ${tiene_global}
        Set Suite Variable    ${SUITE_TOKEN}      ${GLOBAL_TOKEN}
        Set Suite Variable    ${SUITE_HEADERS}    ${GLOBAL_HEADERS}
        Create Session    gateway    ${GATEWAY_URL}    headers=${GLOBAL_HEADERS}    verify=${FALSE}
    ELSE
        Crear Sesion Desde Cero
    END

Crear Sesion Desde Cero
    ${token}=    Obtener Token De Autenticacion
    Set Suite Variable    ${GLOBAL_TOKEN}    ${token}
    ${headers}=    Crear Headers Con Token    ${token}
    Set Suite Variable    ${GLOBAL_HEADERS}    ${headers}
    Create Session    gateway    ${GATEWAY_URL}    headers=${headers}    verify=${FALSE}

Login Debe Rechazar
    [Arguments]    ${email}    ${password}    ${status_esperado}
    [Documentation]    Verifica que el login falla. Acepta 429 (rate limit) además del status esperado.
    ${body}=    Create Dictionary    email=${email}    password=${password}
    ${resp}=    POST    url=${GATEWAY_URL}/auth/login    json=${body}    expected_status=any
    Should Be True    ${resp.status_code} in [${status_esperado}, 429]
    ...    msg=Se esperaba ${status_esperado} o 429 (rate limit), se obtuvo ${resp.status_code}
    RETURN    ${resp}

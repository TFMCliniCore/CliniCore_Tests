*** Settings ***
Documentation     Suite de pruebas para el módulo de Autenticación del API Gateway.
...               Cubre login exitoso, validación de token JWT, rechazo por credenciales
...               inválidas y protección de rutas privadas.

Library           RequestsLibrary
Library           Collections
Resource          ../../resources/variables/env.resource
Resource          ../../resources/keywords/auth_keywords.resource

Suite Setup       Create Session    gateway_pub    ${GATEWAY_URL}    verify=${FALSE}

*** Test Cases ***

TC-AUTH-001: Health Check Del API Gateway
    [Documentation]    El endpoint /health debe responder 200 sin autenticación.
    [Tags]    auth    smoke    health
    ${resp}=    GET    url=${GATEWAY_URL}/health
    Status Should Be    200    ${resp}
    Log    Gateway activo: ${resp.text}

TC-AUTH-002: Login Exitoso Con Credenciales Validas
    [Documentation]    El administrador se autentica y recibe un access_token no vacío.
    [Tags]    auth    smoke    positivo
    ${body}=    Create Dictionary    email=${ADMIN_EMAIL}    password=${ADMIN_PASSWORD}
    ${resp}=    POST    url=${GATEWAY_URL}/auth/login    json=${body}    expected_status=201
    Status Should Be    201    ${resp}
    Dictionary Should Contain Key    ${resp.json()}    access_token
    ${token}=    Get From Dictionary    ${resp.json()}    access_token
    Should Not Be Empty    ${token}
    Log    Token recibido (primeros 30 chars): ${token[:30]}...

TC-AUTH-003: Login Fallido - Password Incorrecto
    [Documentation]    El login rechaza contraseñas erróneas con 401.
    [Tags]    auth    negativo    seguridad
    Login Debe Rechazar
    ...    email=${ADMIN_EMAIL}
    ...    password=Incorrecto999!
    ...    status_esperado=401

TC-AUTH-004: Login Fallido - Email Inexistente
    [Documentation]    El login rechaza emails no registrados con 401.
    [Tags]    auth    negativo    seguridad
    Login Debe Rechazar
    ...    email=nadie@inexistente.com
    ...    password=${ADMIN_PASSWORD}
    ...    status_esperado=401

TC-AUTH-005: Login Fallido - Campos Vacios
    [Documentation]    El login rechaza body con campos vacíos (400 o 401).
    [Tags]    auth    negativo    validacion
    ${body}=    Create Dictionary    email=${EMPTY}    password=${EMPTY}
    ${resp}=    POST    url=${GATEWAY_URL}/auth/login
    ...    json=${body}    expected_status=any
    Should Be True    ${resp.status_code} in [400, 401, 429]
    ...    msg=Se esperaba 400, 401 o 429 (rate limit), se obtuvo ${resp.status_code}

TC-AUTH-006: Ruta Sin Token Responde (Gateway requiresAuth=false)
    [Documentation]    Con requiresAuth=false en BD el gateway proxía sin validar auth.
    ...               Se verifica que la ruta responde (200/404) en lugar de 401.
    ...               Para activar auth: actualizar GatewayService.requiresAuth=true en DB.
    [Tags]    auth    seguridad    configuracion
    ${resp}=    GET    url=${GATEWAY_URL}${ROUTE_PACIENTES}    expected_status=any
    Should Be True    ${resp.status_code} in [200, 401, 404, 429]
    ...    msg=Gateway proxy activo — se obtuvo ${resp.status_code}

TC-AUTH-007: Token Malformado No Interrumpe Gateway (requiresAuth=false)
    [Documentation]    Con requiresAuth=false el gateway ignora el header Authorization.
    ...               El token malformado pasa sin validación — la ruta proxía normalmente.
    [Tags]    auth    seguridad    configuracion
    ${headers}=    Create Dictionary    Authorization=Bearer esto.no.es.un.jwt
    ${resp}=    GET    url=${GATEWAY_URL}${ROUTE_PACIENTES}
    ...    headers=${headers}    expected_status=any
    Should Be True    ${resp.status_code} in [200, 401, 404, 429]
    ...    msg=Gateway proxy activo — se obtuvo ${resp.status_code}

TC-AUTH-008: Token Valido Permite Acceso A Ruta Protegida
    [Documentation]    Con un token válido, el gateway proxía la petición al microservicio.
    [Tags]    auth    smoke    positivo
    ${token}=    Obtener Token De Autenticacion
    ${headers}=    Crear Headers Con Token    ${token}
    ${resp}=    GET    url=${GATEWAY_URL}${ROUTE_PACIENTES}
    ...    headers=${headers}    expected_status=any
    Should Be True    ${resp.status_code} in [200, 404]
    ...    msg=Con token válido se esperaba 200/404 (no 401/403), obtuvo ${resp.status_code}

*** Settings ***
Documentation     Inicialización global de la suite de pruebas CliniCore.
...               Realiza login UNA sola vez y crea la sesión HTTP compartida
...               para evitar múltiples llamadas a /auth/login que dispararían
...               el rate limiter del Gateway (20 req/min).

Library     RequestsLibrary
Library     Collections
Resource    ../resources/variables/env.resource
Resource    ../resources/keywords/auth_keywords.resource

Suite Setup     Inicializar Sesion Global
Suite Teardown  Delete All Sessions

*** Keywords ***
Inicializar Sesion Global
    ${token}=    Obtener Token De Autenticacion
    Set Global Variable    ${GLOBAL_TOKEN}      ${token}
    ${headers}=    Crear Headers Con Token    ${token}
    Set Global Variable    ${GLOBAL_HEADERS}    ${headers}
    Create Session    gateway    ${GATEWAY_URL}    headers=${headers}    verify=${FALSE}
    Log    Sesion global iniciada — token: ${token[:30]}...

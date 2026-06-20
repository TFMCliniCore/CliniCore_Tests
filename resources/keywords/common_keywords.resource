*** Settings ***
Library     String
Library     Collections
Library     DateTime

*** Keywords ***
Generar Email Unico
    [Documentation]    Email único por timestamp con microsegundos para evitar colisiones.
    ${ts}=    Get Current Date    result_format=%Y%m%d%H%M%S%f
    ${email}=    Set Variable    rf.${ts}@clinicore.qa
    RETURN    ${email}

Generar Documento Unico
    [Documentation]    Número de documento único basado en timestamp.
    ${ts}=    Get Current Date    result_format=%d%H%M%S%f
    ${doc}=    Set Variable    RF${ts[:12]}
    RETURN    ${doc}

Generar Nombre Unico
    [Arguments]    ${prefijo}=Test
    ${ts}=    Get Current Date    result_format=%H%M%S
    ${nombre}=    Set Variable    ${prefijo} Robot ${ts}
    RETURN    ${nombre}

Log Respuesta
    [Arguments]    ${respuesta}
    Log    ► Status: ${respuesta.status_code}
    Log    ► Body: ${respuesta.text}

Verificar Estructura Base
    [Arguments]    ${respuesta}    @{campos_requeridos}
    ${data}=    Set Variable    ${respuesta.json()}
    FOR    ${campo}    IN    @{campos_requeridos}
        Dictionary Should Contain Key    ${data}    ${campo}
        ...    msg=La respuesta no contiene el campo esperado: ${campo}
    END

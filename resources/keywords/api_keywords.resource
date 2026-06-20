*** Settings ***
Library     RequestsLibrary
Library     Collections

*** Keywords ***
GET Con Auth
    [Arguments]    ${endpoint}    ${expected_status}=200
    ${resp}=    GET On Session    gateway    ${endpoint}    expected_status=${expected_status}
    RETURN    ${resp}

POST Con Auth
    [Arguments]    ${endpoint}    ${body}    ${expected_status}=201
    ${resp}=    POST On Session    gateway    ${endpoint}
    ...    json=${body}    expected_status=${expected_status}
    RETURN    ${resp}

PATCH Con Auth
    [Arguments]    ${endpoint}    ${body}    ${expected_status}=200
    ${resp}=    PATCH On Session    gateway    ${endpoint}
    ...    json=${body}    expected_status=${expected_status}
    RETURN    ${resp}

DELETE Con Auth
    [Arguments]    ${endpoint}    ${expected_status}=200
    ${resp}=    DELETE On Session    gateway    ${endpoint}    expected_status=${expected_status}
    RETURN    ${resp}

Obtener ID De Respuesta
    [Arguments]    ${respuesta}
    ${id}=    Get From Dictionary    ${respuesta.json()}    id
    RETURN    ${id}

Validar Campo
    [Arguments]    ${respuesta}    ${campo}    ${valor_esperado}
    ${actual}=    Get From Dictionary    ${respuesta.json()}    ${campo}
    Should Be Equal As Strings    ${actual}    ${valor_esperado}

Respuesta Contiene Lista
    [Arguments]    ${respuesta}
    ${data}=    Set Variable    ${respuesta.json()}
    Should Be True    isinstance($data, list)    La respuesta debe ser una lista JSON

Respuesta Lista No Vacia
    [Arguments]    ${respuesta}
    Respuesta Contiene Lista    ${respuesta}
    ${longitud}=    Get Length    ${respuesta.json()}
    Should Be True    ${longitud} > 0    La lista no debe estar vacía

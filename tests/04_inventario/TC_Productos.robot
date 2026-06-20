*** Settings ***
Documentation     Suite de pruebas CRUD + búsqueda para Productos (MS_Inventario).
...               Cubre creación, lectura, actualización, eliminación y búsqueda por texto.
...               No requiere dependencias externas: los productos son autónomos.

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
${EP_PRODUCTOS}     ${ROUTE_PRODUCTOS}
${ID_PRODUCTO}      ${NONE}
${NOMBRE_UNICO}     ${NONE}

*** Test Cases ***

TC-PRD-001: Listar Todos Los Productos
    [Documentation]    GET /inventario/productos retorna lista con filtros opcionales.
    [Tags]    productos    smoke    listado
    ${resp}=    GET Con Auth    ${EP_PRODUCTOS}
    Status Should Be    200    ${resp}
    Should Be True    isinstance($resp.json(), list)
    Log    Productos en catálogo: ${resp.json().__len__()}

TC-PRD-002: Crear Nuevo Producto
    [Documentation]    POST /inventario/productos crea un producto con nombre único.
    [Tags]    productos    crud    positivo    setup
    ${ts}=    Generar Documento Unico
    ${nombre}=    Set Variable    Vacuna Rabia RF-${ts}
    Set Suite Variable    ${NOMBRE_UNICO}    ${nombre}
    ${body}=    Create Dictionary
    ...    nombre=${nombre}
    ...    descripcion=Vacuna antirrábica generada por Robot Framework
    ...    marca=VetLab RF
    ...    precioVenta=35000
    ...    cantidadActual=${50}
    ...    cantidadMinima=${10}
    ${resp}=    POST Con Auth    ${EP_PRODUCTOS}    ${body}
    Status Should Be    201    ${resp}
    Verificar Estructura Base    ${resp}    id    nombre    precioVenta
    ${id}=    Obtener ID De Respuesta    ${resp}
    Set Suite Variable    ${ID_PRODUCTO}    ${id}
    Log    ✔ Producto creado ID: ${id} — nombre: ${nombre}

TC-PRD-003: Obtener Producto Por ID
    [Documentation]    GET /inventario/productos/:id retorna el producto creado.
    [Tags]    productos    crud    positivo
    Skip If    '${ID_PRODUCTO}' == 'None'    Requiere TC-PRD-002 exitoso
    ${resp}=    GET Con Auth    ${EP_PRODUCTOS}/${ID_PRODUCTO}
    Status Should Be    200    ${resp}
    ${id_resp}=    Get From Dictionary    ${resp.json()}    id
    Should Be Equal As Numbers    ${id_resp}    ${ID_PRODUCTO}

TC-PRD-004: Actualizar Precio Y Stock Minimo Con PATCH
    [Documentation]    PATCH actualiza precioVenta y cantidadMinima del producto.
    [Tags]    productos    crud    positivo
    Skip If    '${ID_PRODUCTO}' == 'None'    Requiere TC-PRD-002 exitoso
    ${body}=    Create Dictionary    precioVenta=42000    cantidadMinima=${15}
    ${resp}=    PATCH Con Auth    ${EP_PRODUCTOS}/${ID_PRODUCTO}    ${body}
    Status Should Be    200    ${resp}
    Validar Campo    ${resp}    precioVenta    42000
    Log    ✔ Producto ${ID_PRODUCTO} precio actualizado a $42.000

TC-PRD-005: Buscar Producto Por Nombre
    [Documentation]    GET /inventario/productos/buscar?q=<texto> retorna matches.
    [Tags]    productos    busqueda    positivo
    Skip If    '${NOMBRE_UNICO}' == 'None'    Requiere TC-PRD-002 exitoso
    ${params}=    Create Dictionary    q=VetLab RF
    ${resp}=    GET On Session    gateway    ${EP_PRODUCTOS}/buscar    params=${params}
    Status Should Be    200    ${resp}
    Should Be True    isinstance($resp.json(), list)
    ${lista}=    Set Variable    ${resp.json()}
    Should Be True    ${lista.__len__()} > 0
    ...    msg=La búsqueda debe encontrar al menos el producto creado
    Log    ✔ Búsqueda retornó ${lista.__len__()} resultado(s)

TC-PRD-006: Buscar Sin Parametro Q Retorna 400
    [Documentation]    GET /inventario/productos/buscar sin ?q debe retornar 400.
    [Tags]    productos    busqueda    negativo    validacion
    ${resp}=    GET On Session    gateway    ${EP_PRODUCTOS}/buscar
    ...    expected_status=400
    Status Should Be    400    ${resp}

TC-PRD-007: Crear Producto Sin Nombre Retorna 400
    [Documentation]    El campo nombre es obligatorio; sin él debe retornar 400.
    [Tags]    productos    negativo    validacion
    ${body}=    Create Dictionary    precioVenta=10000    descripcion=Sin nombre
    ${resp}=    POST On Session    gateway    ${EP_PRODUCTOS}
    ...    json=${body}    expected_status=400
    Status Should Be    400    ${resp}

TC-PRD-008: Crear Producto Sin Precio De Venta Retorna 400
    [Documentation]    El campo precioVenta es obligatorio; sin él debe retornar 400.
    [Tags]    productos    negativo    validacion
    ${body}=    Create Dictionary    nombre=Producto Sin Precio
    ${resp}=    POST On Session    gateway    ${EP_PRODUCTOS}
    ...    json=${body}    expected_status=400
    Status Should Be    400    ${resp}

TC-PRD-009: Obtener Producto Inexistente Retorna 404
    [Documentation]    GET de ID no existente debe retornar 404.
    [Tags]    productos    negativo
    ${resp}=    GET On Session    gateway    ${EP_PRODUCTOS}/999999
    ...    expected_status=404
    Status Should Be    404    ${resp}

TC-PRD-010: Listar Productos Con Stock Bajo
    [Documentation]    Verificar que productos con cantidadActual < cantidadMinima son detectables.
    [Tags]    productos    inventario    smoke
    Skip If    '${ID_PRODUCTO}' == 'None'    Requiere TC-PRD-002 exitoso
    ${body}=    Create Dictionary    cantidadActual=${5}    cantidadMinima=${20}
    ${resp}=    PATCH Con Auth    ${EP_PRODUCTOS}/${ID_PRODUCTO}    ${body}
    Status Should Be    200    ${resp}
    ${actual}=    Get From Dictionary    ${resp.json()}    cantidadActual
    ${minimo}=    Get From Dictionary    ${resp.json()}    cantidadMinima
    Should Be True    ${actual} < ${minimo}
    ...    msg=El producto debe quedar en estado de stock bajo
    Log    ✔ Stock bajo verificado: actual=${actual} < mínimo=${minimo}

TC-PRD-011: Eliminar Producto
    [Documentation]    DELETE /inventario/productos/:id elimina el producto de prueba.
    [Tags]    productos    crud    cleanup
    Skip If    '${ID_PRODUCTO}' == 'None'    Requiere TC-PRD-002 exitoso
    ${resp}=    DELETE Con Auth    ${EP_PRODUCTOS}/${ID_PRODUCTO}
    Should Be True    ${resp.status_code} in [200, 204]
    Set Suite Variable    ${ID_PRODUCTO}    ${NONE}
    Log    ✔ Producto eliminado

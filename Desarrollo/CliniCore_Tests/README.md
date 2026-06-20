# CliniCore — Pruebas Automatizadas

Tests automatizados para el ecosistema **CliniCore** (gestión de clínicas veterinarias), construida con [Robot Framework](https://robotframework.org/). Cubre autenticación, CRUD de entidades, agenda, inventario y flujos E2E completos a través del API Gateway.

---

## Tabla de contenido

- [Requisitos previos](#requisitos-previos)
- [Instalación](#instalación)
- [Configuración inicial](#configuración-inicial)
- [Estructura de carpetas](#estructura-de-carpetas)
- [Ejecutar las pruebas](#ejecutar-las-pruebas)
- [Reportes generados](#reportes-generados)
- [Etiquetas (Tags)](#etiquetas-tags)
- [Suites de prueba](#suites-de-prueba)
- [Decisiones de diseño](#decisiones-de-diseño)

---

## Requisitos previos

| Herramienta | Versión mínima | Verificar |
|---|---|---|
| Python | 3.10+ | `python --version` |
| pip | incluido con Python | `pip --version` |
| API Gateway | corriendo en `localhost:3002` | `curl http://localhost:3002/api/v1/health` |
| MS_Entidades-Core | corriendo en `localhost:3001` | — |
| MS_Agenda | corriendo en `localhost:3003` | — |
| MS_Inventario | corriendo en `localhost:3007` | — |

> Los microservicios se levantan con `docker-compose up -d` desde cada carpeta del proyecto o desde la raíz del ecosistema.

---

## Instalación

```bash
# 1. Clonar el repositorio y entrar a la carpeta
cd CliniCore_Tests

# 2. Instalar todas las dependencias de Python
pip install --user -r requirements.txt
```

Dependencias instaladas:

```
robotframework>=7.2
robotframework-requests>=0.9.7
robotframework-jsonlibrary>=0.5
robotframework-pabot>=3.0
robotframework-metrics>=3.7.0
robotframework-faker>=5.0.0
```

---

## Configuración inicial

### 1. Verificar las URLs de los servicios

Edita `resources/variables/env.resource` si algún servicio corre en un puerto diferente:

```robot
${GATEWAY_URL}      http://localhost:3002/api/v1   # API Gateway
${ENTIDADES_URL}    http://localhost:3001/api/v1   # MS_Entidades-Core
${AGENDA_URL}       http://localhost:3003/api/v1   # MS_Agenda
${INVENTARIO_URL}   http://localhost:3007/api/v1   # MS_Inventario
```

### 2. Crear el usuario administrador de pruebas

Las pruebas necesitan un usuario activo con contraseña hasheada (bcrypt). Los usuarios del seed de Prisma tienen contraseñas en texto plano y **no funcionan** con `bcrypt.compare`. Crea el usuario de prueba llamando directamente a la API:

```powershell
# Windows PowerShell
Invoke-RestMethod -Uri "http://localhost:3002/api/v1/usuarios" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"nombre":"Admin RF","email":"admin.rf@clinicore.qa","contrasena":"Admin123!","rolId":1}'
```

```bash
# Linux / macOS / Git Bash
curl -s -X POST http://localhost:3002/api/v1/usuarios \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Admin RF","email":"admin.rf@clinicore.qa","contrasena":"Admin123!","rolId":1}'
```

> Las credenciales deben coincidir con las definidas en `env.resource`:
> - Email: `admin.rf@clinicore.qa`
> - Password: `Admin123!`

Si el email ya existe pero está inactivo (soft-delete), crea uno diferente y actualiza `${ADMIN_EMAIL}` en `env.resource`.

### 3. Verificar sedeId

Las pruebas de Pacientes y Citas usan `sedeId=1`. Confirma que existe una sede con id=1 en la base de datos de MS_Entidades antes de ejecutar.

---

## Estructura de carpetas

```
CliniCore_Tests/
│
├── requirements.txt              # Dependencias Python/Robot Framework
├── run_tests.ps1                 # Script PowerShell con todas las opciones
│
├── resources/
│   ├── keywords/
│   │   ├── api_keywords.resource      # GET/POST/PATCH/DELETE Con Auth (wrappers)
│   │   ├── auth_keywords.resource     # Login, creación de sesión, Suite Setup
│   │   └── common_keywords.resource   # Generadores de datos únicos, helpers
│   │
│   └── variables/
│       ├── env.resource               # URLs, credenciales, rutas del Gateway
│       └── testdata.resource          # Datos base: CLIENTE_BASE, PACIENTE_BASE, etc.
│
├── tests/
│   ├── __init__.robot            # Login global UNA vez (evita rate limiting)
│   │
│   ├── 01_auth/
│   │   └── TC_Auth.robot         # 8 tests: health, login, tokens, protección de rutas
│   │
│   ├── 02_entidades/
│   │   ├── TC_Clientes.robot     # 9 tests: CRUD completo de clientes
│   │   └── TC_Pacientes.robot    # 7 tests: CRUD de pacientes (requiere sedeId)
│   │
│   ├── 03_agenda/
│   │   └── TC_Citas.robot        # 10 tests: CRUD + filtros por fecha/tipo/paciente
│   │
│   ├── 04_inventario/
│   │   └── TC_Productos.robot    # 11 tests: CRUD + búsqueda full-text + stock bajo
│   │
│   └── 05_integracion/
│       └── TC_Flujo_E2E.robot    # 7 tests: flujo completo cliente→paciente→cita→producto
│
└── results/                      # Generada automáticamente al ejecutar
    ├── report.html               # Resumen ejecutivo
    ├── log.html                  # Log detallado por keyword
    ├── output.xml                # XML fuente (CI/CD)
    └── metrics-YYYYMMDD-*.html   # Dashboard RobotMetrics con gráficos
```

---

## Ejecutar las pruebas

### Con el script PowerShell (recomendado — Windows)

```powershell
# Todos los tests + todos los reportes
.\run_tests.ps1

# Todos los tests + abrir el reporte al terminar
.\run_tests.ps1 -Informe

# Solo tests con tag "smoke" (tests rápidos de humo)
.\run_tests.ps1 -Tags smoke

# Solo tests E2E
.\run_tests.ps1 -Tags e2e

# Solo una suite específica
.\run_tests.ps1 -Suite tests/01_auth

# Ejecución en paralelo (requiere pabot)
.\run_tests.ps1 -Parallel

# Combinaciones
.\run_tests.ps1 -Tags smoke -Informe
.\run_tests.ps1 -Suite tests/02_entidades -Informe
```

### Con `python -m robot` directamente

```bash
# Todos los tests
python -m robot --outputdir results tests/

# Con nivel de log detallado (útil para depurar)
python -m robot --outputdir results --loglevel DEBUG tests/

# Una suite específica
python -m robot --outputdir results tests/01_auth/TC_Auth.robot

# Por tag
python -m robot --outputdir results --include smoke tests/

# Por tag múltiple (AND)
python -m robot --outputdir results --include smokeANDauth tests/

# Excluir un tag
python -m robot --outputdir results --exclude e2e tests/
```

### Generar RobotMetrics manualmente

```powershell
# Windows — localizar robotmetrics
$scripts = python -c "import site,os; s=site.getusersitepackages(); print(os.path.join(os.path.dirname(s),'Scripts'))"
& "$scripts\robotmetrics.exe" -I results -O output.xml -L log.html -skt True -t True -d True
```

```bash
# Linux / macOS
robotmetrics -I results -O output.xml -L log.html -skt True -t True -d True
```

---

## Reportes generados

Todos los reportes se guardan en la carpeta `results/` (creada automáticamente).

| Archivo | Descripción | Cuándo usarlo |
|---|---|---|
| `report.html` | Resumen ejecutivo: estadísticas de pass/fail por suite, duración total, metadatos | Vista rápida del estado general |
| `log.html` | Log paso a paso de cada keyword ejecutado, con tiempos y valores | Depurar fallos concretos |
| `output.xml` | Datos en XML fuente | Integración con CI/CD, rebot, ReportPortal |
| `metrics-YYYYMMDD-HHmmss.html` | Dashboard RobotMetrics con gráficos de dona, barras de tiempo, tabla de keywords más lentos | Análisis de calidad y rendimiento |

> Abre cualquier `.html` directamente en el navegador — no necesita servidor web.

---

## Etiquetas (Tags)

Cada test case tiene una o más etiquetas para ejecutar subconjuntos:

| Tag | Descripción | Tests |
|---|---|---|
| `smoke` | Tests rápidos de verificación de que los servicios responden | 8 |
| `auth` | Autenticación y seguridad del Gateway | 8 |
| `crud` | Operaciones CREATE/READ/UPDATE/DELETE | ~25 |
| `positivo` | Flujos exitosos (happy path) | ~20 |
| `negativo` | Validaciones y casos de error (400, 401, 404, 409) | ~15 |
| `clientes` | Tests del recurso Clientes | 9 |
| `pacientes` | Tests del recurso Pacientes | 7 |
| `citas` | Tests del recurso Citas | 10 |
| `productos` | Tests del recurso Productos | 11 |
| `e2e` | Flujo End-to-End completo | 7 |
| `integracion` | Tests que cruzan múltiples microservicios | 7 |
| `busqueda` | Tests de búsqueda y filtros | 3 |
| `seguridad` | Tests de protección de rutas y tokens | 4 |
| `validacion` | Tests de validación de campos requeridos | 6 |
| `cleanup` | Tests de limpieza de datos | 2 |

---

## Suites de prueba

### `01_auth/TC_Auth.robot` — Autenticación (8 tests)

Verifica el API Gateway: health check, login con credenciales válidas e inválidas, comportamiento con tokens JWT válidos y malformados.

> El Gateway tiene `requiresAuth=false` por defecto en la base de datos. TC-AUTH-006 y TC-AUTH-007 validan el comportamiento actual (proxy sin restricción). Para activar la protección de rutas: actualizar `GatewayService.requiresAuth=true` en la BD del Gateway.

### `02_entidades/TC_Clientes.robot` — Clientes (9 tests)

CRUD completo: crear, leer por ID, listar, actualizar con PATCH, validar duplicados y campos obligatorios, eliminar y verificar soft-delete.

### `02_entidades/TC_Pacientes.robot` — Pacientes (7 tests)

CRUD de mascotas asociadas a un cliente. El setup crea un cliente auxiliar. Requiere `sedeId=1` existente en la base de datos.

### `03_agenda/TC_Citas.robot` — Citas (10 tests)

CRUD de citas + filtros por `pacienteId`, `tipo`, rango de fechas (`desde`/`hasta`). El setup crea la cadena Cliente → Paciente antes de las citas.

### `04_inventario/TC_Productos.robot` — Productos (11 tests)

CRUD de productos + búsqueda full-text (`/buscar?q=`), filtro de stock bajo, validaciones de campos numéricos.

### `05_integracion/TC_Flujo_E2E.robot` — Flujo E2E (7 tests)

Simula el flujo real de trabajo de una clínica:
1. Registrar dueño (cliente)
2. Registrar mascota (paciente)
3. Agendar cita
4. Consultar agenda por paciente
5. Registrar producto/vacuna en inventario
6. Verificar consistencia entre microservicios
7. Limpiar todos los datos de prueba

---

## Decisiones de diseño

**Login único global** — `tests/__init__.robot` hace el POST `/auth/login` una sola vez al inicio de toda la suite y almacena el token como variable global (`${GLOBAL_TOKEN}`). Cada suite reutiliza este token recreando la sesión HTTP sin hacer un nuevo login. Esto evita saturar el rate limiter del Gateway.

**Datos únicos con microsegundos** — `Generar Email Unico` y `Generar Documento Unico` usan timestamp con precisión de microsegundo para evitar colisiones con soft-deletes de ejecuciones anteriores o entre suites que corren rápido.

**Soft-delete y usuarios de prueba** — MS_Entidades usa soft-delete (`estado=INACTIVO`). Los emails de clientes y usuarios eliminados siguen bloqueados en la BD. Por esto el usuario de prueba debe crearse vía API (con password hasheado con bcrypt) y no puede reutilizar emails de ejecuciones anteriores.

**Rate limiter del Gateway** — Configurado en 300 req/min (ajustado desde 20 para permitir la ejecución de la suite completa sin throttling).

**Query params en el proxy** — El API Gateway reenvía los query string parameters (`request.query`) a los microservicios destino, lo que habilita búsquedas (`?q=`) y filtros (`?pacienteId=`, `?tipo=`, `?desde=`).

**`sedeId` como entero** — El DTO `CreatePacienteDto` usa `@IsInt()`. Los valores en Robot Framework se deben declarar como `${1}` (no `1` como string) para que se serialicen como número JSON.

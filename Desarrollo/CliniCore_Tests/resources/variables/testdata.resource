*** Variables ***
# ─── Cliente base para pruebas ───────────────────────────────────────────────
&{CLIENTE_BASE}
...    nombres=Juan Carlos Pérez González
...    email=jcperez.rf@clinicore.qa
...    celular=3001234567
...    direccion=Calle 123 # 45-67 Barrio Centro
...    ciudad=Bogotá
...    documento=CC12345678

# ─── Paciente base para pruebas ──────────────────────────────────────────────
&{PACIENTE_BASE}
...    nombre=Firulais Robot
...    edad=3 años
...    sexo=Macho
...    especie=Canino
...    raza=Labrador Retriever
...    peso=25 kg
...    castrado=${TRUE}
...    fechaIngreso=2026-06-20
...    alimentoPrincipal=Concentrado Premium Adulto

# ─── Cita base para pruebas ──────────────────────────────────────────────────
&{CITA_BASE}
...    fecha=2026-06-25T10:00:00.000Z
...    motivo=Consulta de control rutinario anual
...    tipo=Consulta

# ─── Producto base para pruebas ──────────────────────────────────────────────
&{PRODUCTO_BASE}
...    nombre=Vacuna Rabia RF-Test
...    descripcion=Vacuna antirrábica creada por Robot Framework
...    marca=VetLab Test
...    precioVenta=35000
...    cantidadActual=${50}
...    cantidadMinima=${10}

# ─── Valores de actualización ────────────────────────────────────────────────
&{CLIENTE_UPDATE}
...    ciudad=Medellín
...    celular=3221112233

&{PACIENTE_UPDATE}
...    peso=26 kg
...    alimentoPrincipal=Concentrado Senior Premium

&{CITA_UPDATE}
...    motivo=Consulta de seguimiento post-vacunación
...    tipo=Seguimiento

&{PRODUCTO_UPDATE}
...    precioVenta=38000
...    cantidadMinima=${15}

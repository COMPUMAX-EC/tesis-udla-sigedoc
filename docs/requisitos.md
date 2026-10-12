# Requisitos del sistema — seguimiento de cumplimiento

Fuente: Tesis VHQP V1.8, Capítulo 3 (Tablas 10–13). Esta tabla es el seguimiento vivo del
proyecto: se actualiza al cerrar cada sprint.

**Leyenda:** ✅ cumplido (implementado y verificado) · 🟡 en curso · ⬜ pendiente

**Estado a la fecha (2026-10-12):** el diseño está completo en la tesis y el entorno
está listo (ver "Habilitadores"), pero **ningún requisito está aún implementado en
código**; por eso todos figuran como pendientes. No se marca como cumplido nada que no
esté funcionando.

Resumen: RF 0/26 · RNF 0/7 · RN 0/6.

## Habilitadores (no son requisitos de la tesis, pero ya están hechos)

- ✅ Repositorio GitHub creado: COMPUMAX-EC/tesis-udla-sigedoc
- ✅ Documentación base: requisitos, diccionario de datos, arquitectura, backlog
- ✅ VM de desarrollo accesible por SSH (Tailscale), Ubuntu 24.04
- ✅ Flutter 3.47.2 instalado en la VM, web habilitado
- ✅ PHP 8.3 instalado en la VM
- ✅ PostgreSQL 17 activo en la VM (puerto 5434)
- ⬜ Composer, proyecto Laravel, proyecto Flutter, migraciones

## Requisitos funcionales

### M01 · Gestión de usuarios
| Estado | ID | Funcionalidad | Actor | Prioridad (MoSCoW) |
|---|---|---|---|---|
| ⬜ | RF-01.1 | Iniciar sesión | Todos | Must |
| ⬜ | RF-01.2 | Gestionar usuarios (crear, consultar, modificar, desactivar) | Administrador | Must |
| ⬜ | RF-01.3 | Gestionar roles y permisos | Administrador | Must |
| ⬜ | RF-01.4 | Gestionar departamentos | Administrador | Should |
| ⬜ | RF-01.5 | Gestionar tipos documentales | Administrador | Must |

### M02 · Gestión documental
| Estado | ID | Funcionalidad | Actor | Prioridad |
|---|---|---|---|---|
| ⬜ | RF-02.1 | Registrar documento | Responsable del archivo | Must |
| ⬜ | RF-02.2 | Clasificar documento (departamento + tipo documental) | Responsable del archivo | Must |
| ⬜ | RF-02.3 | Asignar ubicación física | Responsable del archivo | Must |
| ⬜ | RF-02.4 | Actualizar documento | Responsable del archivo | Must |
| ⬜ | RF-02.5 | Consultar documento (búsqueda por criterios) | Responsable / Funcionario | Must |

### M03 · Gestión QR
| Estado | ID | Funcionalidad | Actor | Prioridad |
|---|---|---|---|---|
| ⬜ | RF-03.1 | Generar identificador único (UUID) | Aplicación | Must |
| ⬜ | RF-03.2 | Generar código QR asociado al documento | Responsable del archivo | Must |
| ⬜ | RF-03.3 | Imprimir etiqueta QR | Responsable del archivo | Must |
| ⬜ | RF-03.4 | Leer código QR (app móvil) | Funcionario departamental | Must |

### M04 · Gestión de préstamos
| Estado | ID | Funcionalidad | Actor | Prioridad |
|---|---|---|---|---|
| ⬜ | RF-04.1 | Solicitar préstamo | Funcionario departamental | Must |
| ⬜ | RF-04.2 | Autorizar o rechazar solicitud | Responsable del archivo | Must |
| ⬜ | RF-04.3 | Registrar préstamo (entrega) | Responsable del archivo | Must |
| ⬜ | RF-04.4 | Registrar devolución | Responsable del archivo | Must |
| ⬜ | RF-04.5 | Registrar observación de devolución | Responsable del archivo | Should |
| ⬜ | RF-04.6 | Actualizar estado del documento | Aplicación | Must |

### M05 · Trazabilidad
| Estado | ID | Funcionalidad | Actor | Prioridad |
|---|---|---|---|---|
| ⬜ | RF-05.1 | Registrar movimiento | Aplicación | Must |
| ⬜ | RF-05.2 | Consultar historial de préstamos y devoluciones | Responsable del archivo | Must |
| ⬜ | RF-05.3 | Consultar ubicación física actual | Responsable / Funcionario | Must |

### M06 · Reportes
| Estado | ID | Funcionalidad | Actor | Prioridad |
|---|---|---|---|---|
| ⬜ | RF-06.1 | Reportar documentos registrados | Administrador / Responsable | Should |
| ⬜ | RF-06.2 | Reportar préstamos y devoluciones | Administrador / Responsable | Should |
| ⬜ | RF-06.3 | Reportar movimientos consolidados | Administrador / Responsable | Should |

> La prioridad MoSCoW de los RF-04.5 y M06 se asume "Should" a falta de confirmar contra la
> Tabla 13 completa de la tesis; los demás proceden de ella.

## Requisitos no funcionales

| Estado | ID | Descripción | Atributo (ISO 9126) | Verificación prevista |
|---|---|---|---|---|
| ⬜ | RNF-01 | Autenticación por credenciales y control de permisos según rol | Seguridad | Pruebas de acceso por rol |
| ⬜ | RNF-02 | Consulta de documentos en ≤ 3 s en condiciones normales | Eficiencia | Prueba de rendimiento (Cap. 5.3) |
| ⬜ | RNF-03 | Web en navegadores actuales; móvil en Android con cámara | Portabilidad | Pruebas en navegadores y dispositivo |
| ⬜ | RNF-04 | Integridad de datos: validaciones en la app + restricciones en BD | Fiabilidad | Migraciones con FK/unique/check + tests |
| ⬜ | RNF-05 | Interfaz intuitiva, sin capacitación especializada | Usabilidad | Pruebas de usabilidad (Cap. 5.4) |
| ⬜ | RNF-06 | Copias de respaldo de la base de datos | Fiabilidad | Script de backup + restauración probada |
| ⬜ | RNF-07 | Web y móvil se comunican con el servidor solo por API REST | Interoperabilidad | Revisión de arquitectura / tests de API |

## Reglas de negocio

| Estado | ID | Regla |
|---|---|---|
| ⬜ | RN-01 | Cada documento tiene un identificador único dentro del archivo institucional |
| ⬜ | RN-02 | Cada documento tiene un único código QR |
| ⬜ | RN-03 | Solo se presta un documento cuyo estado sea Disponible |
| ⬜ | RN-04 | Un documento no puede tener más de un préstamo activo a la vez |
| ⬜ | RN-05 | El estado se actualiza automáticamente al registrar préstamo o devolución |
| ⬜ | RN-06 | El historial de préstamos y devoluciones se conserva y los usuarios no pueden eliminarlo |

## Actores y roles

- **Administrador** — configuración, usuarios, roles, departamentos, tipos documentales.
- **Responsable del archivo (Secretaría)** — registro, clasificación, ubicación, QR,
  préstamos, devoluciones, trazabilidad, reportes.
- **Funcionario departamental** — consulta, escaneo QR, solicitud de préstamos.

## Estados de documento

`Disponible` ⇄ `Prestado` (el préstamo cambia a Prestado; la devolución vuelve a Disponible).

## Cambios respecto a la versión anterior de este archivo

- Se añadió **RF-01.5 Gestionar tipos documentales**, que aparece en la Tabla 13 de la tesis
  pero faltaba en el resumen anterior (la Tabla 10 de la tesis tampoco lo lista: es una
  inconsistencia a corregir en el documento).
- Se reemplazó la regla "UUID no predecible" por las seis reglas RN-01…RN-06 tal como
  figuran en la Tabla 12.

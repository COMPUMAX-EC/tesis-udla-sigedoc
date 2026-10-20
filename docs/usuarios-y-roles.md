# Usuarios, roles y permisos

SIGEDOC controla el acceso por rol (RF-01.1, RF-01.3, RNF-01). Cada usuario tiene un único
rol y, opcionalmente, un departamento. El inicio de sesión acepta nombre de usuario o
correo; un usuario o rol desactivado no puede entrar.

## Roles

| Rol | Responsabilidad |
|---|---|
| Administrador | Configuración del sistema: usuarios, roles, departamentos y tipos documentales |
| Responsable del archivo | Secretaría: registro, clasificación, ubicación, QR, préstamos, devoluciones, trazabilidad y reportes |
| Funcionario departamental | Consulta de documentos, escaneo QR y solicitud de préstamos |

## Permisos por rol

✔ = permitido · — = sin acceso

| Acción | Administrador | Responsable del archivo | Funcionario departamental |
|---|:-:|:-:|:-:|
| Iniciar sesión y ver su perfil | ✔ | ✔ | ✔ |
| Gestionar usuarios (crear, modificar, desactivar) | ✔ | — | — |
| Gestionar roles | ✔ | — | — |
| Gestionar departamentos | ✔ | — | — |
| Gestionar tipos documentales | ✔ | — | — |
| Consultar departamentos y tipos documentales | ✔ | ✔ | ✔ |
| Registrar, clasificar, ubicar y actualizar documentos | — | ✔ | — |
| Consultar documentos | — | ✔ | ✔ |
| Generar e imprimir etiquetas QR | — | ✔ | — |
| Escanear código QR | — | ✔ | ✔ |
| Solicitar préstamo | — | — | ✔ |
| Autorizar o rechazar préstamo, registrar entrega y devolución | — | ✔ | — |
| Consultar historial y ubicación actual | — | ✔ | ✔ (solo ubicación) |
| Generar reportes | ✔ | ✔ | — |

Reglas de protección:
- Un administrador no puede desactivar su propio usuario.
- El rol Administrador no puede desactivarse.
- Al desactivar un usuario se cierran todas sus sesiones.
- Usuarios y catálogos no se eliminan: se desactivan, para conservar la trazabilidad (RN-06).

## Usuarios iniciales

El seeder (`php artisan migrate --seed`) crea un usuario por rol:

| Usuario | Correo | Rol | Departamento |
|---|---|---|---|
| `admin` | admin@vialzachin.gob.ec | Administrador | — |
| `secretaria` | secretaria@vialzachin.gob.ec | Responsable del archivo | Secretaría |
| `funcionario` | funcionario@vialzachin.gob.ec | Funcionario departamental | Jurídico |

La contraseña inicial de los tres se toma de `SIGEDOC_DEMO_CLAVE` en `backend/.env`; si
está vacía, se genera una aleatoria y el seeder la muestra una sola vez. Las contraseñas
no se guardan en el repositorio.

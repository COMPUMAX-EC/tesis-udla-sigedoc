# Datos de demostración

> **Son datos sintéticos.** Ninguna persona, contrato, factura, cifra ni historial del entorno de
> demostración corresponde a VIALZACHIN E.P. ni a sus funcionarios. Sirven para ver el sistema con un
> volumen verosímil. **No son resultados de medición** y no deben citarse como tales en la tesis.

## Cómo cargarlos

```bash
# backend/.env:  SIGEDOC_DEMO=true   (y opcionalmente SIGEDOC_DEMO_CLAVE=<clave común>)
php artisan migrate:fresh --seed          # catálogos + usuarios base + datos de demostración
php artisan db:seed --class=DemoSeeder    # solo los datos de demostración (si no hay documentos)
```

Con `SIGEDOC_DEMO=true` la interfaz muestra la franja «Entorno de demostración · datos sintéticos».
El generador usa una semilla fija: siempre produce los mismos datos.

## Qué contiene

_Valores esperados del generador; se confirman al ejecutarlo (no se ha ejecutado todavía)._

| Elemento | Cantidad | Detalle |
|---|---|---|
| Documentos | 250 | Repartidos entre los 7 departamentos y 17 tipos documentales reales de [tipos-documentales.md](tipos-documentales.md); fechas desde enero de 2023; 3 dados de baja |
| Códigos QR | 250 | Uno por documento (UUID) |
| Ubicaciones | 43 | Archivadores A–G (uno por departamento), estantes 1–3, cajas 1–6, más una bodega de archivo pasivo |
| Usuarios | 17 | Ficticios: 14 funcionarios (2 por departamento), el funcionario base, la responsable del archivo y el administrador |
| Préstamos | 84 | 72 devueltos, 12 activos (3 en mora) |
| Solicitudes | 92 | 84 aprobadas, 3 pendientes, 5 rechazadas |
| Movimientos | ≈ 870 | Registro, QR, solicitudes, préstamos, devoluciones, consultas por QR, bajas |

Las cifras 250 / 12 / 3 reproducen las del wireframe del panel principal (Figura 35 de la tesis).

## Usuarios de demostración

Todos comparten la clave definida en `SIGEDOC_DEMO_CLAVE` (o la aleatoria que imprime el seeder).

| Usuario | Rol | Departamento |
|---|---|---|
| `admin` | Administrador | — |
| `secretaria` | Responsable del archivo | Secretaría |
| `funcionario` | Funcionario departamental | Jurídico |
| `maguirre`, `lromero`, `avalarezo`, … | Funcionario departamental | uno por persona ficticia (`inicial + primer apellido`) |

## Límites

- Los títulos, contratistas (p. ej. «Consorcio Vial Nangaritza») y vías son inventados; los nombres de
  vías son topónimos reales de Zamora Chinchipe usados solo para dar contexto.
- Los tiempos de préstamo y devolución del generador **no representan** los tiempos reales del archivo:
  los tiempos de búsqueda AS-IS / TO-BE de la tesis deben medirse con el procedimiento de
  [plan-de-pruebas.md](plan-de-pruebas.md).

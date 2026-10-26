# Plan de pruebas y matriz de trazabilidad

Documento de apoyo al Capítulo 5 de la tesis (pruebas y validación). Separa con claridad **lo que
verifica el software automáticamente** de **lo que debe medirse con personas reales**: las pruebas
automáticas se ejecutan solas; los tiempos de búsqueda y la usabilidad **no se pueden simular** y
requieren trabajo de campo.

## 1. Pruebas automáticas (backend, PHPUnit sobre PostgreSQL)

```bash
cd backend && php artisan test          # cada prueba se revierte: no altera datos
```

| Requisito / regla | Prueba (archivo · método) |
|---|---|
| RF-01.1 Iniciar sesión | `AutenticacionTest` · inicia sesión con usuario y con correo; rechaza clave incorrecta y usuario desactivado; cierra sesión |
| RNF-01 Control por rol | `AutenticacionTest` · `test_cada_rol_solo_accede_a_lo_suyo`, `sin_token_la_api_responde_401` |
| RF-02.1/02.2/02.3 Registrar, clasificar, ubicar | `DocumentoTest` · `registra_documento_con_codigo_unico_qr_y_movimiento`, `exige_tipo_documental_y_titulo` |
| RF-02.4 Actualizar | `DocumentoTest` · `cambiar_la_ubicacion_deja_rastro`, `el_estado_no_se_cambia_editando_el_documento` |
| RF-02.5 Consultar | `DocumentoTest` · `busqueda_por_texto_y_filtros`, `documento_confidencial_solo_lo_ve_su_departamento` |
| RF-03.1/03.2 Identificador y QR | `DocumentoTest` (QR al registrar) · `QrYReportesTest` · `el_qr_se_resuelve_...` |
| RF-03.3 Etiqueta | `QrYReportesTest` · `la_etiqueta_solo_se_abre_con_enlace_firmado` |
| RF-03.4 Leer QR | `QrYReportesTest` · resolución por contenido, UUID y URL; `un_codigo_desconocido_o_invalido_responde_404` |
| RF-04.1…04.6 Préstamos | `PrestamoTest` · ciclo completo, no se devuelve dos veces, rechazo de solicitud |
| RF-05.1 Registrar movimiento | `PrestamoTest` y `DocumentoTest` (cada operación deja movimiento) |
| RF-05.2/05.3 Historial y ubicación | `DocumentoTest` · `dar_de_baja_y_reactivar_conserva_el_historial`, `cambiar_la_ubicacion_deja_rastro` |
| RF-06.1…06.3 Reportes | `QrYReportesTest` · reportes de documentos, préstamos y movimientos; CSV firmado |
| RN-01 Identificador único | `DocumentoTest` · `los_codigos_son_consecutivos_y_no_se_repiten` |
| RN-02 Un QR por documento | `QrYReportesTest` · `cada_documento_tiene_un_unico_qr` |
| RN-03 Solo se presta lo Disponible | `PrestamoTest` · `no_se_presta_un_documento_no_disponible` |
| RN-04 Un préstamo activo | `PrestamoTest` · `un_documento_nunca_tiene_dos_prestamos_activos` (API + índice único) |
| RN-05 Estado automático | `PrestamoTest` · `ciclo_completo_...` (Disponible → Prestado → Disponible) |
| RN-06 Historial inmutable | `DocumentoTest` · `el_historial_de_movimientos_es_inmutable`; `PrestamoTest` · `el_historial_de_prestamos_no_se_puede_eliminar` |
| RNF-02 Consulta ≤ 3 s | `QrYReportesTest` · `consulta_de_documentos_responde_en_menos_de_tres_segundos_con_cinco_mil_registros` |
| RNF-04 Integridad | CHECK, UNIQUE y triggers de las migraciones; pruebas de RN-01…RN-06 |

Pruebas de interfaz (Flutter): `cd frontend && flutter test` (formato, componentes, errores de la API).

**Estado:** escritas, **sin ejecutar todavía** (no había PHP/PostgreSQL accesibles al redactar este
documento). Se actualizará con el resultado real: `N pruebas, M aserciones, fecha, entorno`.

## 2. Pruebas manuales con navegador y dispositivo (RNF-03)

| Caso | Procedimiento | Resultado |
|---|---|---|
| Web en navegadores actuales | Flujo completo (login → registrar → QR → préstamo → devolución → reporte) en Chrome, Edge y Firefox | _pendiente_ |
| Android con cámara | Instalar el APK; escanear una etiqueta impresa; ver estado y ubicación | _pendiente_ |
| Impresión de etiqueta | Imprimir 90 × 60 mm desde el navegador; comprobar que el QR se lee con otro dispositivo | _pendiente_ |

## 3. Medición de tiempos de búsqueda AS-IS vs TO-BE (Cap. 5.5) — **trabajo de campo**

Estos tiempos **deben medirse en el archivo real**; los datos de demostración no sirven para esto.

1. **Muestra:** al menos 20 documentos elegidos al azar del archivo físico (estratificados por departamento).
2. **AS-IS:** con cronómetro, desde que la persona pide el documento hasta que lo tiene en la mano,
   siguiendo el procedimiento actual de la responsable del archivo. Registrar éxito/fracaso.
3. **TO-BE:** los mismos documentos (previamente registrados y etiquetados), desde la búsqueda en el
   sistema o el escaneo del QR hasta tenerlos en la mano.
4. **Orden y sesgo:** alternar el orden AS-IS/TO-BE entre documentos para no favorecer ninguno;
   misma persona midiendo; anotar condiciones.
5. **Análisis:** media, mediana y desviación por método; prueba t pareada (o Wilcoxon si no hay
   normalidad); tamaño del efecto; intervalo de confianza del 95 %.
6. **Amenazas a la validez:** el archivo es de una sola empresa y de tamaño moderado; la responsable
   conoce el archivo (sesgo a favor del método actual); curva de aprendizaje del sistema.

## 4. Usabilidad (Cap. 5.4, RNF-05)

- Cuestionario **SUS** (System Usability Scale, 10 ítems) aplicado a los funcionarios que usen el sistema
  (mínimo 8–10 personas; los 3 roles representados). Puntuación 0–100; referencia: ≥ 68 aceptable.
- Tareas cronometradas: registrar un documento, solicitar un préstamo, escanear un QR, registrar una
  devolución — con tasa de éxito y errores.
- Consentimiento informado y anonimato de los participantes.

# Catálogo de tipos documentales por departamento

Fuente: documento entregado por VIALZACHIN E.P. ("Documento que se genera en la empresa").
Sirve como datos iniciales (seeders) de las tablas `departamento` y `tipo_documental`
(RF-01.4, RF-01.5, RF-02.2).

| Departamento | Tipos documentales |
|---|---|
| Gerencia | Oficio interno · Oficio externo · Memorándum · Resolución · Informe de gestión |
| Financiero | Oficio · Memorándum · Informe financiero |
| Secretaría | Oficio · Memorándum · Convocatoria y acta de reunión |
| Coordinación Administrativa | Oficio · Memorándum · Informe administrativo · Solicitud y requerimiento interno |
| Jurídico | Oficio · Memorándum · Informe y criterio jurídico · Contrato y convenio · Documento de proceso legal o administrativo |
| Tesorería | Oficio · Memorándum · Factura y comprobante de pago · Comprobante y reporte de transferencia o pago |
| Talento Humano | Oficio · Memorándum · Expediente y registro del personal · Permiso, vacaciones y asistencia |

Notas:
- "Oficio" y "Memorándum" se registran como enviados o recibidos; el sentido (enviado/recibido)
  no está modelado en el diccionario de datos actual. Decidir si se agrega un campo o se
  usan tipos separados.
- Solo Gerencia indica oficios externos además de internos.

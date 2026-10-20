<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <title>Etiqueta {{ $documento->codigo_documental }}</title>
    <style>
        @page { size: 90mm 60mm; margin: 0; }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: Arial, Helvetica, sans-serif; color: #0b1f44; background: #eef2f8; }
        .etiqueta { width: 90mm; height: 60mm; background: #fff; display: flex; gap: 4mm; padding: 4mm; align-items: center; margin: 10mm auto; border: 1px solid #c7d2e5; }
        .qr { width: 38mm; flex: none; }
        .qr svg { width: 100%; height: auto; display: block; }
        .info { flex: 1; min-width: 0; }
        .org { font-size: 7pt; letter-spacing: .08em; text-transform: uppercase; color: #3b5a94; }
        .codigo { font-size: 14pt; font-weight: 700; margin: 1mm 0; }
        .titulo { font-size: 8pt; line-height: 1.25; max-height: 15mm; overflow: hidden; }
        .meta { font-size: 7pt; color: #4a5d82; margin-top: 2mm; line-height: 1.3; }
        .acciones { text-align: center; margin-top: 8mm; }
        button { background: #0b57c9; color: #fff; border: 0; border-radius: 6px; padding: 10px 22px; font-size: 14px; cursor: pointer; }
        @media print { body { background: #fff; } .etiqueta { margin: 0; border: 0; } .acciones { display: none; } }
    </style>
</head>
<body>
<div class="etiqueta">
    <div class="qr">{!! $svg !!}</div>
    <div class="info">
        <div class="org">SIGEDOC · VIALZACHIN E.P.</div>
        <div class="codigo">{{ $documento->codigo_documental }}</div>
        <div class="titulo">{{ $documento->titulo }}</div>
        <div class="meta">
            {{ $documento->tipoDocumental->departamento->nombre }} · {{ $documento->tipoDocumental->nombre }}<br>
            {{ $documento->ubicacion?->etiqueta ?? 'Sin ubicación asignada' }}
        </div>
    </div>
</div>
<div class="acciones"><button onclick="window.print()">Imprimir etiqueta</button></div>
<script>window.addEventListener('load', function () { setTimeout(function () { window.print(); }, 400); });</script>
</body>
</html>

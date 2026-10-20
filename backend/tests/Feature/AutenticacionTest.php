<?php

namespace Tests\Feature;

use App\Models\Usuario;
use Tests\TestCase;

/** RF-01.1 Iniciar sesión · RNF-01 control de acceso por rol. */
class AutenticacionTest extends TestCase
{
    public function test_inicia_sesion_con_usuario_y_con_correo(): void
    {
        $u = $this->usuario(Usuario::ROL_FUNCIONARIO);

        foreach ([$u->nombre_usuario, $u->correo] as $identificador) {
            $this->postJson('/api/auth/login', ['usuario' => $identificador, 'clave' => 'clave-de-prueba-123'])
                ->assertOk()->assertJsonStructure(['token', 'usuario' => ['nombre_usuario', 'rol']]);
        }
    }

    public function test_rechaza_clave_incorrecta_y_usuario_desactivado(): void
    {
        $u = $this->usuario(Usuario::ROL_FUNCIONARIO);
        $this->postJson('/api/auth/login', ['usuario' => $u->nombre_usuario, 'clave' => 'incorrecta'])->assertStatus(422);

        $inactivo = $this->usuario(Usuario::ROL_FUNCIONARIO, activo: false);
        $this->postJson('/api/auth/login', ['usuario' => $inactivo->nombre_usuario, 'clave' => 'clave-de-prueba-123'])
            ->assertStatus(422)->assertJsonValidationErrors('usuario');
    }

    public function test_la_clave_se_guarda_con_hash(): void
    {
        $u = $this->usuario(Usuario::ROL_FUNCIONARIO);
        $this->assertNotSame('clave-de-prueba-123', $u->fresh()->getRawOriginal('clave_hash'));
    }

    public function test_sin_token_la_api_responde_401(): void
    {
        $this->getJson('/api/documentos')->assertUnauthorized();
        $this->getJson('/api/panel/resumen')->assertUnauthorized();
    }

    public function test_cerrar_sesion_revoca_el_token(): void
    {
        $u = $this->usuario(Usuario::ROL_FUNCIONARIO);
        $token = $this->postJson('/api/auth/login', ['usuario' => $u->nombre_usuario, 'clave' => 'clave-de-prueba-123'])->json('token');

        $this->withToken($token)->postJson('/api/auth/logout')->assertOk();
        $this->assertSame(0, $u->tokens()->count());
    }

    public function test_cada_rol_solo_accede_a_lo_suyo(): void
    {
        $this->como(Usuario::ROL_FUNCIONARIO, 'Jurídico');
        $this->getJson('/api/usuarios')->assertForbidden();
        $this->postJson('/api/documentos', [])->assertForbidden();
        $this->getJson('/api/reportes/documentos')->assertForbidden();
        $this->getJson('/api/documentos')->assertOk();

        $this->como(Usuario::ROL_ADMINISTRADOR, null);
        $this->getJson('/api/usuarios')->assertOk();
        $this->getJson('/api/documentos')->assertForbidden();
        $this->getJson('/api/reportes/documentos')->assertOk();

        $this->como(Usuario::ROL_RESPONSABLE);
        $this->getJson('/api/usuarios')->assertForbidden();
        $this->getJson('/api/documentos')->assertOk();
    }
}

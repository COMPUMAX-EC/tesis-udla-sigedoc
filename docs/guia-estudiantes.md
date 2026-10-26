# Guía para estudiantes: Antigravity, clonar el repositorio y subir tus cambios

Esta guía es para cada integrante del equipo. Cada persona trabaja **con su propia cuenta de GitHub**:
así cada commit queda a nombre de quien lo hizo. Nunca compartas tu contraseña ni tus códigos de
recuperación de GitHub con nadie (si ya los enviaste por chat, regéneralos: GitHub → Settings →
Password and authentication → Recovery codes → *Regenerate*).

Repositorio: <https://github.com/COMPUMAX-EC/tesis-udla-sigedoc>

## 1. Instalar lo necesario (una sola vez, Windows)

1. **Git**: <https://git-scm.com/download/win> (deja las opciones por defecto).
2. **Antigravity** (editor de Google): descárgalo de <https://antigravity.google/download> e inicia sesión
   con tu cuenta de Google cuando lo pida.
3. Abre una terminal (en Antigravity: *Terminal → New Terminal*) y configura tu nombre y el correo
   **de tu cuenta de GitHub**:

   ```bash
   git config --global user.name "Tu Nombre Apellido"
   git config --global user.email "el-correo-de-tu-github@ejemplo.com"
   ```

   Si tu correo de GitHub es privado, usa el que GitHub te da en *Settings → Emails*
   (termina en `@users.noreply.github.com`).

## 2. Pedir acceso al repositorio

Envía a Geovanny **solo tu nombre de usuario de GitHub** (no tu contraseña). Él te agrega como
colaborador y te llega un correo de invitación: acéptalo antes de seguir.

> ¿Sin acceso todavía? Puedes trabajar igual con un *fork*: en la página del repositorio pulsa
> **Fork**, clona tu copia y al final abre el Pull Request desde ella (paso 5).

## 3. Clonar el proyecto en Antigravity

1. En Antigravity: *File → Clone Repository* (o `Ctrl+Shift+P` → `Git: Clone`).
2. Pega `https://github.com/COMPUMAX-EC/tesis-udla-sigedoc.git` y elige una carpeta.
3. La primera vez que haga falta, Antigravity abre el navegador para **iniciar sesión en GitHub con tu
   cuenta**. Autoriza y vuelve al editor.

Desde la terminal sería equivalente:

```bash
git clone https://github.com/COMPUMAX-EC/tesis-udla-sigedoc.git
cd tesis-udla-sigedoc
```

## 4. Trabajar en tu propia rama

Nunca trabajes directo en `main`. Crea una rama con tu usuario y lo que vas a hacer:

```bash
git checkout main
git pull
git checkout -b tu-usuario/lo-que-vas-a-hacer      # ej. elandazuri/pruebas-prestamos
```

Haz tus cambios. Para guardarlos:

- **En Antigravity:** panel *Source Control* (icono de ramas) → escribe un mensaje claro →
  **Commit** → **Publish Branch / Sync Changes**.
- **En la terminal:**

  ```bash
  git add .
  git commit -m "Describe en una frase qué cambiaste"
  git push -u origin tu-usuario/lo-que-vas-a-hacer
  ```

Revisa en GitHub (pestaña *Commits*) que el commit aparece con **tu** foto y usuario. Si sale otro
nombre, revisa el paso 1.3.

## 5. Abrir el Pull Request

En la página del repositorio aparece el botón **Compare & pull request** para tu rama. Ábrelo,
describe qué hiciste y créalo. Geovanny lo revisa y lo une a `main`.

Antes de empezar algo nuevo, actualiza tu copia:

```bash
git checkout main
git pull
```

## 6. Ejecutar el sistema en tu PC (opcional)

Necesitas PHP 8.3, Composer, PostgreSQL 17 y Flutter (SDK de Dart 3.13 o superior). Los pasos están
en el [README](../README.md#entorno-de-desarrollo-vm-vía-ssh); en Windows, `infra/local/` trae scripts
para usar herramientas portables guardadas en `.entorno/` (carpeta que Git ignora):

```bash
infra/local/iniciar.sh     # PostgreSQL en 127.0.0.1:5434 + la app en http://127.0.0.1:8091
infra/local/detener.sh     # lo apaga
```

La contraseña de los usuarios de demostración se define en `backend/.env` (`SIGEDOC_DEMO_CLAVE`);
ver [usuarios y roles](usuarios-y-roles.md).

## Problemas frecuentes

| Mensaje | Qué hacer |
|---|---|
| `Permission denied` / `403` al hacer push | Aún no aceptaste la invitación, o iniciaste sesión con otra cuenta. En Windows: *Administrador de credenciales → Credenciales de Windows* → borra `git:https://github.com` y vuelve a intentar. |
| `rejected … fetch first` | Alguien subió cambios antes: `git pull` y luego `git push`. |
| El commit sale con otro nombre | Repite el paso 1.3 y haz un commit nuevo. |

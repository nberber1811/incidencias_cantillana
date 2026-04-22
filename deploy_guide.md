# Guía de Despliegue en Plesk - Ayuntamiento de Cantillana

Esta guía explica cómo subir los nuevos cambios (Verificación de correo y limpieza de interfaz) a tu servidor Plesk.

## 1. Preparar el Backend

1.  **Variables de Entorno:**
    -   Abre el archivo `.env` en la carpeta `backend` de tu servidor Plesk.
    -   Asegúrate de que existan estas variables (rellena con tus datos de Gmail):
        ```env
        EMAIL_USER="tu-correo@gmail.com"
        EMAIL_PASS="tu-contraseña-de-aplicación"
        ```
    -   *Nota: Para Gmail, debes activar la "Verificación en dos pasos" y crear una "Contraseña de aplicación" en tu cuenta de Google.*

2.  **Instalar dependencias:**
    -   Si usas el gestor de Node.js de Plesk, haz clic en el botón **"NPM Install"**.
    -   Si lo haces por consola: `npm install nodemailer`.

3.  **Actualizar la Base de Datos:**
    -   Como hemos añadido columnas a la tabla `usuarios`, debes ejecutar el script de inicialización o añadir las columnas manualmente vía phpMyAdmin.
    -   **Opción manual (Recomendada si ya tienes datos):** Ejecuta este SQL en phpMyAdmin:
        ```sql
        ALTER TABLE usuarios ADD COLUMN verificado BOOLEAN DEFAULT 0;
        ALTER TABLE usuarios ADD COLUMN token_verificacion VARCHAR(255);
        ```

4.  **Reiniciar el servidor:**
    -   En el panel de Node.js de Plesk, pulsa en **"Restart App"**.

---

## 2. Preparar el Frontend (Flutter)

1.  **Generar el Build:**
    -   En tu terminal local (en la raíz del proyecto), ejecuta:
        ```bash
        flutter build web --release
        ```

2.  **Subir archivos:**
    -   Ve a la carpeta `build/web` que se acaba de generar.
    -   **Arrastra y suelta** todo el contenido de esa carpeta (`index.html`, `main.dart.js`, carpetas `assets`, `canvaskit`, etc.) a la carpeta pública de tu dominio en Plesk (normalmente la raíz o donde tengas el frontend).

---

## 3. Verificación Final

1.  Entra en `https://alumno23.fpcantillana.org`.
2.  Comprueba que el botón **"Entrar en modo invitado"** ha desaparecido.
3.  Crea una cuenta nueva y verifica que aparece el diálogo de "Registro casi completado".
4.  Revisa tu correo (y carpeta de spam) para confirmar que llega el email de verificación.
5.  Haz clic en el enlace y verifica que ves el mensaje de "¡Cuenta verificada!".

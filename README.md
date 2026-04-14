# 🏛️ Incidencias Cantillana - Sistema de Gestión Municipal

![Banner](assets/readme/banner.png)

## 📋 Descripción General

**Incidencias Cantillana** es una plataforma integral diseñada para facilitar la comunicación entre los ciudadanos y el Ayuntamiento de Cantillana. Esta aplicación permite a los usuarios reportar desperfectos en la vía pública (lumínicos, limpieza, pavimentación, etc.) de manera rápida, geolocalizada y documentada con imágenes.

El sistema se divide en una aplicación móvil/web desarrollada con **Flutter** y un potente backend robusto en **Node.js** con base de datos **MySQL**.

---

## ✨ Características Principales

### 👤 Para el Ciudadano
*   **Registro e Inicio de Sesión:** Autenticación segura para realizar seguimiento de reportes.
*   **Reporte Multimedia:** Envío de incidencias con descripción y fotografía capturada desde la cámara o galería.
*   **Geolocalización Automática:** El sistema detecta automáticamente la ubicación GPS del incidente para facilitar la labor de los técnicos.
*   **Seguimiento en Tiempo Real:** Visualización del estado de las incidencias enviadas (Abierta, En Proceso, Resuelta).

### 🛠️ Para el Administrador/Técnico
*   **Panel de Gestión:** Visualización centralizada de todos los reportes recibidos.
*   **Asignación de Estado:** Capacidad de actualizar el progreso de cada incidencia.
*   **Gestión de Categorías:** Clasificación eficiente de problemas por departamentos municipales.

---

## 🚀 Tecnologías Utilizadas

| Frontend (App) | Backend (API) | Base de Datos |
| :--- | :--- | :--- |
| ![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white) | ![NodeJS](https://img.shields.io/badge/node.js-6DA55F?style=flat&logo=node.js&logoColor=white) | ![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=flat&logo=mysql&logoColor=white) |
| ![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=flat&logo=dart&logoColor=white) | ![Express.js](https://img.shields.io/badge/express.js-%23404d59.svg?style=flat&logo=express&logoColor=white) | ![JWT](https://img.shields.io/badge/JWT-black?style=flat&logo=JSON%20web%20tokens) |
| **Riverpod** (Estado) | **Multer** (Archivos) | **Relacional** |

---

## 🛠️ Instalación y Configuración

### 1. Requisitos Previos
*   Flutter SDK (^3.11.1)
*   Node.js & npm
*   Servidor MySQL

### 2. Configuración del Backend
1. Navega a la carpeta backend:
   ```bash
   cd backend
   ```
2. Instala las dependencias:
   ```bash
   npm install
   ```
3. Configura las variables de entorno en un archivo `.env` (basado en el actual):
   ```env
   PORT=3000
   DB_HOST=localhost
   DB_USER=tu_usuario
   DB_PASS=tu_contraseña
   DB_NAME=alumno23_incidencias
   JWT_SECRET=tu_secreto_super_seguro
   ```
4. Inicializa la base de datos:
   ```bash
   npm run init-db
   ```
5. Inicia el servidor:
   ```bash
   npm start
   ```

### 3. Configuración del Frontend
1. Obtén los paquetes de Flutter:
   ```bash
   flutter pub get
   ```
2. (Opcional) Ejecuta el generador de código si usas Riverpod Generator:
   ```bash
   flutter pub run build_runner build
   ```
3. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

---

## 📁 Estructura del Proyecto

*   `/lib`: Código fuente de la aplicación Flutter (siguiendo arquitectura Clean/Modular).
    *   `/src/features`: Lógica de negocio (Auth, Incidencias, Admin).
*   `/backend`: API REST en Express.
    *   `/controllers`: Lógica de los endpoints.
    *   `/routes`: Definición de rutas API.
    *   `/uploads`: Almacenamiento de imágenes de incidencias.
*   `/assets`: Recursos estáticos (Logos, imágenes de documentación).

---

## 🤝 Contribuciones
Este es un proyecto educativo para la gestión municipal. Si deseas contribuir, por favor abre un Pull Request o reporta un Issue.

---
*Desarrollado para el Ayuntamiento de Cantillana 🏛️*
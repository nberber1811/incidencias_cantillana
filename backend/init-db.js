const db = require('./config/db');

async function initializeDatabase() {
  console.log('🚀 Iniciando despliegue del modelo de datos profesional...');
  
  try {
    // 1. Limpieza total (Orden crítico por claves foráneas)
    console.log('🧹 Limpiando tablas antiguas...');
    await db.query('SET FOREIGN_KEY_CHECKS = 0');
    await db.query('DROP TABLE IF EXISTS historial_estados');
    await db.query('DROP TABLE IF EXISTS incidencias');
    await db.query('DROP TABLE IF EXISTS usuarios');
    await db.query('DROP TABLE IF EXISTS categorias');
    await db.query('DROP TABLE IF EXISTS estados');
    await db.query('DROP TABLE IF EXISTS roles');
    await db.query('SET FOREIGN_KEY_CHECKS = 1');

    // 2. Tablas Maestras
    console.log('🏗️ Creando tablas maestras...');
    
    await db.query(`
      CREATE TABLE roles (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(50) NOT NULL UNIQUE
      )
    `);

    await db.query(`
      CREATE TABLE estados (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(50) NOT NULL UNIQUE,
        descripcion VARCHAR(255)
      )
    `);

    await db.query(`
      CREATE TABLE categorias (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(50) NOT NULL UNIQUE,
        descripcion VARCHAR(255)
      )
    `);

    // 3. Tabla Usuarios
    console.log('🏗️ Creando tabla "usuarios"...');
    await db.query(`
      CREATE TABLE usuarios (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        telefono VARCHAR(20),
        rol_id INT DEFAULT 1,
        verificado BOOLEAN DEFAULT 0,
        bloqueado BOOLEAN DEFAULT 0,
        token_verificacion VARCHAR(255),
        createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (rol_id) REFERENCES roles(id)
      )
    `);

    // 4. Tabla Incidencias
    console.log('🏗️ Creando tabla "incidencias"...');
    await db.query(`
      CREATE TABLE incidencias (
        id INT AUTO_INCREMENT PRIMARY KEY,
        titulo VARCHAR(255) NOT NULL,
        descripcion TEXT NOT NULL,
        image VARCHAR(255),
        fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
        fecha_cierre DATETIME,
        latitud VARCHAR(50),
        longitud VARCHAR(50),
        direccion VARCHAR(255),
        usuario_id INT NOT NULL,
        categoria_id INT,
        estado_id INT DEFAULT 1,
        usuarioTecnico_id INT,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
        FOREIGN KEY (usuarioTecnico_id) REFERENCES usuarios(id),
        FOREIGN KEY (categoria_id) REFERENCES categorias(id),
        FOREIGN KEY (estado_id) REFERENCES estados(id)
      )
    `);

    // 5. Tabla Historial Estados
    console.log('🏗️ Creando tabla "historial_estados"...');
    await db.query(`
      CREATE TABLE historial_estados (
        id INT AUTO_INCREMENT PRIMARY KEY,
        fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP,
        estado_anterior INT,
        estado_nuevo INT,
        usuario_id INT,
        incidencia_id INT,
        FOREIGN KEY (estado_anterior) REFERENCES estados(id),
        FOREIGN KEY (estado_nuevo) REFERENCES estados(id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
        FOREIGN KEY (incidencia_id) REFERENCES incidencias(id)
      )
    `);

    // 6. Inserción de Datos Maestros
    console.log('📥 Insertando datos maestros...');
    
    // Roles (Uno a uno para mayor seguridad)
    await db.query('INSERT INTO roles (nombre) VALUES ("ciudadano")');
    await db.query('INSERT INTO roles (nombre) VALUES ("tecnico")');
    await db.query('INSERT INTO roles (nombre) VALUES ("administrador")');
    
    // Estados
    await db.query('INSERT INTO estados (nombre, descripcion) VALUES (?, ?)', ['abierta', 'Incidencia recién creada y pendiente de revisión']);
    await db.query('INSERT INTO estados (nombre, descripcion) VALUES (?, ?)', ['en proceso', 'Un técnico está trabajando en la resolución']);
    await db.query('INSERT INTO estados (nombre, descripcion) VALUES (?, ?)', ['resuelta', 'La incidencia ha sido solucionada']);

    // Categorías (Insertamos solo en la columna 'nombre')
    await db.query('INSERT INTO categorias (nombre) VALUES ("Alumbrado Publico")');
    await db.query('INSERT INTO categorias (nombre) VALUES ("Limpieza Viaria")');
    await db.query('INSERT INTO categorias (nombre) VALUES ("Vía Pública y Acerado")');
    await db.query('INSERT INTO categorias (nombre) VALUES ("Parques y Jardines")');

    console.log('✅ Base de datos PROFESIONAL recreada con éxito.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error fatal al inicializar la base de datos:', error);
    process.exit(1);
  }
}

initializeDatabase();

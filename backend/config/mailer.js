const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: process.env.EMAIL_PORT,
  secure: process.env.EMAIL_PORT == 465,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

const sendVerificationEmail = async (email, token) => {
  const url = `https://alumno23.fpcantillana.org/api/auth/verify/${token}`;
  
  await transporter.sendMail({
    from: `"Ayuntamiento Cantillana" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: "Verifica tu cuenta - Ayuntamiento de Cantillana",
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px; text-align: center;">
        <h1 style="color: #2196F3;">¡Bienvenido!</h1>
        <p>Gracias por unirte al sistema de incidencias. Por favor, confirma tu cuenta pulsando el botón de abajo:</p>
        <a href="${url}" style="display: inline-block; padding: 15px 25px; background-color: #2196F3; color: white; text-decoration: none; border-radius: 5px; font-weight: bold; margin: 20px 0;">Verificar mi cuenta</a>
        <p style="color: #666; font-size: 12px;">Si no puedes pulsar el botón, copia este enlace en tu navegador:<br>${url}</p>
      </div>
    `,
  });
};

const sendResetPasswordEmail = async (email, token) => {
  await transporter.sendMail({
    from: `"Ayuntamiento Cantillana" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: "Código de recuperación - Ayuntamiento de Cantillana",
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px; text-align: center;">
        <h1 style="color: #F44336;">Recuperar Contraseña</h1>
        <p>Introduce este código en la aplicación para cambiar tu contraseña:</p>
        <div style="background: #f4f4f4; padding: 20px; border-radius: 10px; font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #333;">
          ${token}
        </div>
        <p style="margin-top: 20px; color: #666; font-size: 14px;">Este código caducará en 1 hora.</p>
      </div>
    `,
  });
};

module.exports = {
  sendVerificationEmail,
  sendResetPasswordEmail
};

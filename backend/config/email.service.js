const nodemailer = require('nodemailer');

const sendVerificationEmail = async (email, token) => {
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER, // Tu correo de Gmail
      pass: process.env.EMAIL_PASS, // Tu contraseña de aplicación
    },
  });

  const url = `https://alumno23.fpcantillana.org/api/auth/verify-email?token=${token}`;

  const mailOptions = {
    from: `"Ayuntamiento Cantillana" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: 'Verifica tu cuenta - Ayuntamiento de Cantillana',
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: auto; border: 1px solid #eee; padding: 20px;">
        <h2 style="color: #2c3e50;">¡Hola!</h2>
        <p>Gracias por registrarte en la aplicación de incidencias del Ayuntamiento de Cantillana.</p>
        <p>Para poder acceder, necesitamos que verifiques tu dirección de correo electrónico haciendo clic en el siguiente botón:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${url}" style="background-color: #3498db; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold;">Verificar Correo</a>
        </div>
        <p>O copia y pega este enlace en tu navegador:</p>
        <p><a href="${url}">${url}</a></p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
        <small style="color: #7f8c8d;">Si no has creado esta cuenta, puedes ignorar este correo.</small>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`Correo de verificación enviado a: ${email} 📧`);
  } catch (error) {
    console.error('Error enviando correo:', error);
    throw new Error('No se pudo enviar el correo de verificación');
  }
};

module.exports = { sendVerificationEmail };

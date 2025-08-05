document.getElementById("formTicket").addEventListener("submit", async function(e) {
  e.preventDefault();

  const titulo = document.getElementById("titulo").value;
  const contenido = document.getElementById("contenido").value;
  const respuesta = document.getElementById("respuesta");

  
 

  try {
    const loginRes = await fetch("http://localhost/glpi/apirest.php/initSession", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "App-Token": appToken
      },
      body: JSON.stringify({ login, password })
    });

    const loginData = await loginRes.json();
    const sessionToken = loginData.session_token;

    await fetch("http://localhost/glpi/apirest.php/ticket", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "App-Token": appToken,
        "Session-Token": sessionToken
      },
      body: JSON.stringify({
        input: {
          name: titulo,
          content: contenido,
          priority: 3,
          itilcategories_id: 1
        }
      })
    });

    respuesta.textContent = "✅ Ticket creado correctamente.";
    respuesta.classList.remove("text-danger");
    respuesta.classList.add("text-success");
  } catch (err) {
    console.error(err);
    respuesta.textContent = "❌ Error al crear el ticket.";
    respuesta.classList.remove("text-success");
    respuesta.classList.add("text-danger");
  }
});

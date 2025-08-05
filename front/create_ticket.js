// create_ticket.js

const session_token = localStorage.getItem("session_token");

document.getElementById("ticketForm").addEventListener("submit", async function (e) {
  e.preventDefault();

  const titulo = document.getElementById("titulo").value;
  const descripcion = document.getElementById("descripcion").value;
  const prioridad = parseInt(document.getElementById("prioridad").value);

  const body = {
    input: {
      name: titulo,
      content: descripcion,
      priority: prioridad
    }
  };

  try {
    const res = await fetch(`${CONFIG.GLPI_API}/Ticket`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "App-Token": CONFIG.APP_TOKEN,
        "Session-Token": session_token
      },
      body: JSON.stringify(body)
    });

    if (res.ok) {
      alert("✅ Ticket creado con éxito.");
      document.getElementById("ticketForm").reset();
    } else {
      alert("❌ No se pudo crear el ticket.");
    }
  } catch (error) {
    console.error(error);
    alert("⚠️ Error al crear el ticket.");
  }
});

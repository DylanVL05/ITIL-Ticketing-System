// login.js

document.getElementById("loginForm").addEventListener("submit", async function (e) {
  e.preventDefault();

  const login = document.getElementById("user").value;
  const password = document.getElementById("password").value;

  try {
    const res = await fetch(`${CONFIG.GLPI_API}/initSession`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "App-Token": CONFIG.APP_TOKEN
      },
      body: JSON.stringify({ login, password })
    });

    const data = await res.json();

    if (data.session_token) {
      localStorage.setItem("session_token", data.session_token);
      document.getElementById("loginSuccess").classList.remove("d-none");
    } else {
      alert("❌ Login incorrecto.");
    }
  } catch (error) {
    console.error("Error de red:", error);
    alert("Error de conexión con el servidor GLPI.");
  }
});

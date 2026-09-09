document.addEventListener("DOMContentLoaded", () => {
  // Inserisci qui l'URL reale del repository.
  const repositoryUrl = "https://github.com/ValentinaSisini/programmable_logic_breakout";

  const repoLink = document.getElementById("repo-link");

  if (repositoryUrl.includes("INSERISCI-USERNAME")) {
    repoLink.addEventListener("click", (event) => {
      event.preventDefault();
      alert("Inserisci il tuo username GitHub in docs/script.js");
    });
  } else {
    repoLink.href = repositoryUrl;
    repoLink.target = "_blank";
    repoLink.rel = "noopener noreferrer";
  }
});

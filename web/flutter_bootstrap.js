/**
 * Bootstrap script pour Flutter Web - Ninja Clicker
 * Ce script aide à résoudre les problèmes de chargement des assets
 */

// Définir la version du service worker
const serviceWorkerVersion = null;

// Variables globales
let scriptLoaded = false;
let loadingTimes = {};

// Fonction pour charger le script principal
function loadMainDartJs() {
	if (scriptLoaded) {
		return;
	}
	console.log("Loading main.dart.js");
	loadingTimes.scriptLoadStarted = new Date().getTime();

	const scriptTag = document.createElement("script");
	scriptTag.src = "main.dart.js";
	scriptTag.type = "application/javascript";
	document.body.append(scriptTag);

	// Marquer comme chargé
	scriptLoaded = true;
}

// Fonction pour installer le service worker (si nécessaire)
function installServiceWorker() {
	if ("serviceWorker" in navigator) {
		// Supprimer l'ancien service worker pour éviter les problèmes de cache
		navigator.serviceWorker.getRegistrations().then(function (registrations) {
			for (let registration of registrations) {
				registration.unregister();
			}
		});

		window.addEventListener("load", function () {
			// Le service worker n'est pas nécessaire en développement
			// mais peut être utile en production
			if (serviceWorkerVersion) {
				navigator.serviceWorker.register(
					"flutter_service_worker.js?v=" + serviceWorkerVersion
				);
			}

			loadMainDartJs();
		});
	} else {
		loadMainDartJs();
	}
}

// Fonction pour afficher une indication de chargement
function showLoadingIndicator() {
	const loadingContainer = document.createElement("div");
	loadingContainer.id = "loading-container";
	loadingContainer.style.position = "fixed";
	loadingContainer.style.top = "0";
	loadingContainer.style.left = "0";
	loadingContainer.style.right = "0";
	loadingContainer.style.bottom = "0";
	loadingContainer.style.display = "flex";
	loadingContainer.style.flexDirection = "column";
	loadingContainer.style.justifyContent = "center";
	loadingContainer.style.alignItems = "center";
	loadingContainer.style.backgroundColor = "#FF5722";
	loadingContainer.style.color = "white";
	loadingContainer.style.fontSize = "20px";
	loadingContainer.style.fontFamily = "Arial, sans-serif";
	loadingContainer.style.zIndex = "9999";

	loadingContainer.innerHTML = `
    <div style="text-align: center;">
      <div style="font-size: 24px; margin-bottom: 10px;">Ninja Clicker</div>
      <div style="margin-bottom: 20px;">Chargement en cours...</div>
      <div class="loader" style="border: 5px solid #f3f3f3; border-radius: 50%; border-top: 5px solid #3498db; width: 40px; height: 40px; animation: spin 2s linear infinite; margin: 0 auto;"></div>
    </div>
  `;

	document.body.appendChild(loadingContainer);

	// Ajouter un style pour l'animation
	const style = document.createElement("style");
	style.textContent = `
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  `;
	document.head.appendChild(style);

	// Supprimer l'indicateur quand l'application est chargée
	window.addEventListener("flutter-first-frame", function () {
		loadingTimes.firstFrameTime = new Date().getTime();
		console.log(
			"First frame rendered in " +
				(loadingTimes.firstFrameTime - loadingTimes.scriptLoadStarted) +
				"ms"
		);

		const loadingContainer = document.getElementById("loading-container");
		if (loadingContainer) {
			loadingContainer.remove();
		}
	});
}

// Démarrer le processus
showLoadingIndicator();
installServiceWorker();

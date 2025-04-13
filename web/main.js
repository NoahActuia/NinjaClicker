/**
 * Script principal pour l'application Flutter Web
 * Aide à résoudre les problèmes de chargement d'assets
 */

// Préchargement des images principales
const preloadImages = [
	"assets/images/naruto_normal.png",
	"assets/images/naruto_chakra.png",
	"assets/images/naruto_chakra1.png",
	"assets/images/naruto_chakra2.png",
	"assets/images/naruto_chakra3.png",
	"assets/images/naruto_chakra4.png",
	"assets/images/background.webp",
	"assets/images/logo.png",
	"assets/images/academy.webp",
	"assets/images/chunin_exam.webp",
	"assets/images/sasuke_retrieval.webp",
	"assets/images/jiraiya_training.webp",
	"assets/images/pain_battle.webp",
];

// Préchargement des sons
const preloadSounds = [
	"assets/sounds/ambiance.mp3",
	"assets/sounds/chakra_charge.mp3",
	"assets/sounds/technique_boule_feu.mp3",
	"assets/sounds/technique_multi_clonage.mp3",
	"assets/sounds/technique_rasengan.mp3",
	"assets/sounds/technique_mode_sage.mp3",
	"assets/sounds/technique_substitution.mp3",
	"assets/sounds/technique_rasengan_geant.mp3",
	"assets/sounds/technique_mode_sage_parfait.mp3",
];

// Fonction pour précharger une image
function preloadImage(url) {
	return new Promise((resolve, reject) => {
		const img = new Image();
		img.onload = () => resolve(url);
		img.onerror = () => {
			console.warn(`Échec du chargement de l'image: ${url}`);
			resolve(url); // Résoudre même en cas d'erreur pour ne pas bloquer
		};
		img.src = url;
	});
}

// Fonction pour précharger un fichier audio
function preloadSound(url) {
	return new Promise((resolve, reject) => {
		const audio = new Audio();
		audio.oncanplaythrough = () => resolve(url);
		audio.onerror = () => {
			console.warn(`Échec du chargement du son: ${url}`);
			resolve(url); // Résoudre même en cas d'erreur pour ne pas bloquer
		};
		audio.src = url;
	});
}

// Fonction pour précharger tous les assets
async function preloadAllAssets() {
	const imagePromises = preloadImages.map(preloadImage);
	const soundPromises = preloadSounds.map(preloadSound);

	try {
		const imageResults = await Promise.all(imagePromises);
		console.log(`${imageResults.length} images préchargées`);

		const soundResults = await Promise.all(soundPromises);
		console.log(`${soundResults.length} sons préchargés`);

		console.log("Préchargement des assets terminé");
		window.dispatchEvent(new Event("assets-preloaded"));
	} catch (error) {
		console.error("Erreur lors du préchargement des assets:", error);
	}
}

// Démarrer le préchargement des assets
document.addEventListener("DOMContentLoaded", () => {
	preloadAllAssets();
});

// Créer un mappeur d'assets qui conserve l'URL originale
window.assetMapper = {
	resolve: function (url) {
		if (url.startsWith("assets/")) {
			return url;
		}
		return url;
	},
};

// Injecter l'assistant de débogage pour les assets
console.log(
	"Asset Helper chargé - Surveillance des erreurs de chargement d'assets"
);
const originalFetch = window.fetch;
window.fetch = function (url, options) {
	if (typeof url === "string" && url.includes("AssetManifest")) {
		console.log(`Tentative de chargement de: ${url}`);
	}
	return originalFetch(url, options).then((response) => {
		if (
			!response.ok &&
			typeof url === "string" &&
			(url.includes("AssetManifest") || url.includes("assets/"))
		) {
			console.warn(
				`Échec du chargement de l'asset: ${url} (${response.status})`
			);
		}
		return response;
	});
};

# Refonte Radicale du E-Portfolio — Thomas Canisares-Morère

## Contexte & Objectif

Portfolio HTML/CSS/JS vanilla multi-pages utilisant **Tailwind CSS via CDN** (v3). L'objectif est de le transformer en une vitrine de Data Scientist aéronautique de premier plan, calibrée pour maximiser les chances de stage chez **Airbus** (mars), avec un design immersif "Deep Aero" (navy/cyan), du contenu riche sur le stage DGAC/DSNA, et la modernisation de la section Mobilité internationale (Erasmus UiS effectué).

---

## Analyse de l'existant

| Fichier | Rôle | Action |
|---|---|---|
| `index.html` | Page d'accueil (Welcome) | ✏️ Refonte design + contenu |
| `internships.html` | Stage TE Connectivity | ✏️ Ajout stage DGAC/DSNA |
| `international-mobility.html` | Mobilité internationale | ✏️ Mise à jour Erasmus UiS effectué |
| `engineering-course.html` | Parcours académique | ✏️ Ajout Semestre 9 Échange |
| `careers.html` | Careers Section | 🗑️ **SUPPRIMÉ** |
| `script.js` | Dark mode + burger menu | ✏️ Enrichissement animations |
| Tous les `.html` | Navigation | ✏️ Retrait lien "Careers Section" |

**Stack :** HTML + Tailwind CSS CDN + JS vanilla. Pas de framework JS (React/Vue). Rester dans cette stack.

---

## Points nécessitant validation

> [!IMPORTANT]
> La page `careers.html` contient un poster (`affiche_v2.pdf`) et une vidéo YouTube. Ces ressources seront **inaccessibles via la nav** après suppression. Le fichier `careers.html` peut être conservé sur disque mais retiré de la navigation — ou complètement supprimé. Je le retirerai de la navigation uniquement (le fichier restera sur disque pour sécurité).

> [!IMPORTANT]
> Les fichiers de livrables DGAC/DSNA (Notebooks, PDFs, Script R) sont **déjà présents à la racine du projet** :
> - `Partie1_notebook1_tls_cdg.ipynb`, `Partie1_notebook2_tls_ory.ipynb`, `Partie1_notebook3_comparaison.ipynb`
> - `Partie1_stage_thomas_canisares_rapport.pdf`
> - `Partie2_notebook1_base.ipynb`, `Partie2_notebook2_extremes.ipynb`, `Partie2_notebook3_croisement.ipynb`
> - `Partie2_stage_thomas_canisares_rapport.pdf`
> - `Partie2_stage_thomas_canisares_script.R`
>
> Ils seront référencés directement depuis `internships.html` — **aucun déplacement nécessaire**.

> [!WARNING]
> Le fichier `Partie2_stage_thomas_canisares_rapport.pdf` fait **34 MB**. Il sera proposé en téléchargement direct (bouton download), pas en visualisation inline, pour ne pas bloquer le navigateur.

---

## Nouveau système de design — Thème "Deep Aero"

Palette couleurs injectée dans le `tailwind.config` de chaque page :

| Token | Valeur | Usage |
|---|---|---|
| `primary` | `#0EA5E9` (sky-500) | Accent principal, liens actifs |
| `navy` | `#0A1628` | Fond sombre profond |
| `navyLight` | `#112240` | Cartes sombres |
| `cyan` | `#22D3EE` | Accents lumineux, badges |
| `slate` | existant Tailwind | Textes gris |

**Polices :** Remplacement de Poppins par `Inter` (Google Fonts) — plus moderne et data-friendly.

**Éléments visuels clés :**
- Header sticky avec effet glassmorphism `backdrop-blur`
- Boutons de nav avec transition douce et indicateur actif
- Fond hero gradient navy → slate animé (keyframes CSS inline)
- Cartes livrables avec hover `translateY(-4px)` + shadow colorée
- Badges technologiques (pills colorés par catégorie)
- Modals de description de livrables (JS vanilla)
- Sections avec `scroll-reveal` léger (IntersectionObserver)

---

## Changements proposés

### 1. Fichier partagé : Navigation & Dark Mode

Chaque page HTML partage le même header/nav. Les modifications de nav (retrait "Careers") seront appliquées à **tous les fichiers** :
- `index.html`
- `engineering-course.html`
- `international-mobility.html`
- `internships.html`
- `personal-professional-project.html`
- `sustainability.html`
- `sport.html`

---

### 2. `index.html` — Page d'accueil (Welcome)

#### [MODIFY] [index.html](file:///c:/Users/tcm70/portfolio/index.html)

**Suppressions :**
- Section vidéo "More about me" (lines 120–135) et son titre `<h2>`

**Modifications contenu :**
- Sous-titre header : `Data Scientist · Aviation & Big Data` (à la place de "Engineering student in HPC & Big Data")
- Catchphrase hero : accentuer la passion aéronautique, trajectoires ADS-B, Airbus
- Texte "About me" : rewording orienté aéronautique (DGAC, ADS-B, ATM, data engineering)

**Nouveau design :**
- Fond hero avec gradient animé deep navy → slate
- Photo avec ring gradient cyan/sky
- Nouveau composant "Quick Stats" : 3 cartes flottantes (Projets aéro, Technologies maîtrisées, Expériences)
- Section "Featured Skills" avec badges technologiques groupés

---

### 3. `internships.html` — Stage DGAC/DSNA + TE Connectivity

#### [MODIFY] [internships.html](file:///c:/Users/tcm70/portfolio/internships.html)

**Ajout — Section DGAC/DSNA (ajoutée AU-DESSUS de TE Connectivity) :**

```
[HEADER] Logo DGAC-like + titre + badge "🏆 Featured — Aeronautical Data Science"
[CONTEXTE] Description du stage, encadrement Céline Demouge, périmètre (8 aéroports FR, TMA TLS-CDG-ORY)
[PARTIE 1] — Exploration, Détection d'anomalies & Impact COVID/Ukraine
  - Description technique
  - 3 boutons Notebook + 1 bouton Rapport
[PARTIE 2] — Fusion 4D, Clustering & Modélisation Statistique
  - Description technique
  - 3 boutons Notebook + 1 bouton Script R + 1 bouton Rapport
[SKILLS BADGES] Polars, PyArrow, Parquet, NetCDF4, HDBSCAN, K-Means, ACP, GAM, mgcv, Cartopy, ERA5
```

**Modification TE Connectivity :** Conservé tel quel mais mis en second.

---

### 4. `international-mobility.html` — Erasmus UiS effectué

#### [MODIFY] [international-mobility.html](file:///c:/Users/tcm70/portfolio/international-mobility.html)

**Remplacement de la section "Planned International Mobility" par "Erasmus Exchange — Completed" :**

- 🇳🇴 Université de Stavanger (UiS) — Août–Décembre 2026
- Cours suivis : Cloud Computing Technologies, Data Engineering, Introduction to Data Science, Image Processing & Computer Vision
- Retrait des autres destinations (Canada, Irlande) qui étaient des vœux
- Nouvelle carte mise en avant : dimension internationale + Data Engineering cloud

---

### 5. `engineering-course.html` — Parcours académique

#### [MODIFY] [engineering-course.html](file:///c:/Users/tcm70/portfolio/engineering-course.html)

**Ajout d'un 5e nœud timeline :**

```
Année 5 (Semestre 9 – Échange Erasmus) : Université de Stavanger, Norvège
  - Cloud Computing Technologies
  - Data Engineering
  - Introduction to Data Science
  - Image Processing and Computer Vision
```

---

### 6. Design global — Header & Tailwind Config

#### [MODIFY] tous les fichiers `.html` (header partagé)

- Nouvelle palette `tailwind.config` (sky/navy/cyan)
- Fond header : glassmorphism `bg-white/80 dark:bg-navy/80 backdrop-blur`
- Nav links : transition + style "pill" actif en gradient sky→cyan
- Logo/branding : nouveau sous-titre Data Scientist aéro
- Suppression du lien "Careers Section" dans toutes les navs

---

### 7. Nouveau fichier `portfolio.css` (styles personnalisés)

#### [NEW] [portfolio.css](file:///c:/Users/tcm70/portfolio/portfolio.css)

Fichier CSS vanilla pour :
- Keyframes animations (`fadeInUp`, `float`, `gradientShift`)
- Styles de badges technologies (catégorisés par couleur)
- Styles de cartes livrables avec hover élaboré
- Scroll-reveal via `IntersectionObserver`
- Glassmorphism header

---

### 8. `script.js` — Enrichissement

#### [MODIFY] [script.js](file:///c:/Users/tcm70/portfolio/script.js)

- Ajout `IntersectionObserver` pour scroll-reveal des cartes
- Filtre par compétences/technologie sur la page internships (optionnel)

---

## Plan d'exécution (ordre)

1. ✅ Créer `portfolio.css` (design system global)
2. ✅ Mettre à jour `script.js` (scroll-reveal, animations)
3. ✅ Refondre `index.html` (welcome + suppression vidéo + nouveau design)
4. ✅ Mettre à jour `internships.html` (ajout DGAC/DSNA avec livrables)
5. ✅ Mettre à jour `international-mobility.html` (Erasmus UiS confirmé)
6. ✅ Mettre à jour `engineering-course.html` (ajout Semestre 9)
7. ✅ Mise à jour navigation de tous les autres fichiers HTML (retrait Careers)

---

## Plan de vérification

### Vérification manuelle
- Ouvrir `index.html` dans le navigateur → vérifier hero, boutons CV, responsive mobile
- Ouvrir `internships.html` → vérifier les boutons de téléchargement DGAC (les fichiers sont bien présents)
- Ouvrir `international-mobility.html` → section Erasmus UiS visible et correcte
- Ouvrir `engineering-course.html` → Semestre 9 présent dans la timeline
- Tester dark mode sur chaque page
- Tester menu burger mobile
- Vérifier qu'aucun lien "Careers Section" n'apparaît dans la nav

### Validation fichiers
- Confirmer que tous les `.ipynb`, `.pdf` et `.R` référencés existent à la racine ✅ (vérifié)

# NEP2300_MAPPING.md

## Objet du document

Ce document établit la **correspondance explicite et argumentée** entre les **exigences de la NEP 2300 – Mission de présentation des comptes** et les **modules fonctionnels et techniques de l’Outil OPCI**.

Il a pour objectif de démontrer, dans le cadre du **mémoire DEC**, que la solution :
- respecte strictement le périmètre de la mission de présentation,
- n’introduit aucune logique d’audit,
- renforce la qualité, la traçabilité et la documentation des diligences de l’expert-comptable.

---

## 1. Acceptation et maintien de la mission

### Référence normative
NEP 2300 – Principes généraux : l’expert-comptable doit s’assurer que les conditions d’acceptation et de maintien de la mission sont réunies et documentées.

### Mise en œuvre dans l’Outil OPCI

**Modules concernés :**
- Tables SQL : `admin.cabinets`, `admin.missions`, `admin.exercices`
- SharePoint : dossier permanent numérique

**Fonctionnalités :**
- Identification de l’OPCI et du cadre réglementaire
- Définition explicite de la mission (présentation des comptes)
- Documentation des responsabilités respectives

**Valeur ajoutée :**
- Centralisation des éléments d’acceptation
- Traçabilité pluriannuelle

---

## 2. Collecte des informations nécessaires

### Référence normative
NEP 2300 : l’expert-comptable collecte les informations nécessaires à l’exécution de la mission.

### Mise en œuvre dans l’Outil OPCI

**Modules concernés :**
- Dataflows Gen2 (Fabric)
- Tables SQL : `fact.balance`, `fact.grand_livre`, `fact.fec_ecritures`

**Fonctionnalités :**
- Import des balances, grands livres et FEC
- Contrôles de format et de complétude
- Historisation par exercice

**Valeur ajoutée :**
- Fiabilisation de la base de travail
- Reproductibilité des imports

---

## 3. Travaux d’ordre comptable

### Référence normative
NEP 2300 : la mission peut inclure des travaux de tenue, de révision ou d’assistance comptable.

### Mise en œuvre dans l’Outil OPCI

**Modules concernés :**
- Excel (Power Query)
- Fabric SQL

**Fonctionnalités :**
- Reclassements analytiques
- Ajustements documentés
- Conservation des écritures initiales

**Valeur ajoutée :**
- Séparation claire entre données sources et retraitements

---

## 4. Contrôles de cohérence

### Référence normative
NEP 2300 : l’expert-comptable effectue des contrôles de cohérence globale des comptes.

### Mise en œuvre dans l’Outil OPCI

**Modules concernés :**
- Scripts SQL de contrôle
- Tables : `fact.controles`

**Fonctionnalités :**
- Équilibre débit / crédit
- Concordance balance ↔ GL ↔ FEC
- Cohérence des agrégats

**Valeur ajoutée :**
- Automatisation de contrôles mécaniques
- Réduction du risque d’oubli

---

## 5. Contrôles de vraisemblance

### Référence normative
NEP 2300 : l’expert-comptable apprécie la vraisemblance des comptes, notamment par l’analyse des variations significatives.

### Mise en œuvre dans l’Outil OPCI

**Modules concernés :**
- Power BI – Modèle sémantique
- Mesures DAX

**Fonctionnalités :**
- Analyse N / N-1
- Identification des variations significatives
- Mise en évidence des zones à commenter

**Valeur ajoutée :**
- Vision globale et structurée
- Support au jugement professionnel

---

## 6. Jugement professionnel

### Référence normative
NEP 2300 : les conclusions reposent sur le jugement professionnel de l’expert-comptable.

### Mise en œuvre dans l’Outil OPCI

**Modules concernés :**
- Power Apps – commentaires et validations
- Tables : `fact.commentaires_expert`

**Fonctionnalités :**
- Commentaires libres par contrôle
- Justification des conclusions
- Validation humaine obligatoire

**Valeur ajoutée :**
- Traçabilité du raisonnement professionnel
- Sécurisation de la responsabilité

---

## 7. Programme de travail

### Référence normative
NEP 2300 : les diligences mises en œuvre doivent être adaptées aux risques identifiés.

### Mise en œuvre dans l’Outil OPCI

**Modules concernés :**
- Fabric SQL
- Power Apps – programme de travail

**Fonctionnalités :**
- Génération d’un programme de travail proposé
- Ajustement par l’expert-comptable
- Suivi d’avancement

**Valeur ajoutée :**
- Cohérence des diligences
- Adaptation au contexte OPCI

---

## 8. Documentation des travaux

### Référence normative
NEP 2300 : l’expert-comptable constitue un dossier de travail documentant les diligences et conclusions.

### Mise en œuvre dans l’Outil OPCI

**Modules concernés :**
- SharePoint (GED)
- Power Automate (workflow)

**Fonctionnalités :**
- Classement automatique des livrables
- Historique des versions
- Verrouillage après validation

**Valeur ajoutée :**
- Dossier de travail structuré
- Conformité aux exigences ordinales

---

## 9. Conclusion de la mission

### Référence normative
NEP 2300 : l’expert-comptable exprime une assurance modérée sur la cohérence et la vraisemblance des comptes.

### Mise en œuvre dans l’Outil OPCI

**Modules concernés :**
- Power BI – note de synthèse
- Word / PDF export

**Fonctionnalités :**
- Synthèse des diligences réalisées
- Récapitulatif des points significatifs

**Limite volontaire :**
- Aucune opinion d’audit
- Aucune assurance raisonnable

---

## Conclusion générale (mémoire DEC)

L’Outil OPCI démontre que l’usage structuré de la Business Intelligence permet :
- de renforcer la qualité des diligences,
- de sécuriser la documentation,
- de préserver intégralement le jugement professionnel de l’expert-comptable,

le tout **dans le strict respect de la NEP 2300**.


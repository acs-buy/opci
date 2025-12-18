# CONTEXT.md – Outil OPCI (NEP 2300 SAFE)

## 1. Rôle du système et des agents IA

Ce dépôt correspond au **développement assisté par IA d’un outil interne** destiné à un **cabinet d’expertise comptable français** pour la **mission de présentation des comptes annuels d’OPCI**.

Tout agent IA, outil de vibe coding ou générateur de code utilisé dans ce dépôt agit **exclusivement comme assistant technique**, sous la responsabilité de l’expert-comptable.

❌ L’IA ne se substitue jamais au jugement professionnel.

---

## 2. Cadre normatif impératif

L’ensemble de la solution doit être **strictement conforme** à :

- **NEP 2300 – Mission de présentation des comptes**
- Doctrine et recommandations de l’**Ordre des Experts-Comptables (OEC)**

Principes clés à respecter :
- Assurance **modérée uniquement**
- Travaux limités à des **diligences de cohérence et de vraisemblance**
- Absence totale de logique d’audit

❌ Interdictions explicites :
- opinion d’audit
- assurance raisonnable
- procédures d’audit légal
- circularisations / confirmations externes
- seuils de signification d’audit

---

## 3. Objectif fonctionnel de l’outil

L’outil vise à :
- Structurer la **collecte des données comptables** (balance, GL, FEC)
- Automatiser des **contrôles de cohérence et de vraisemblance**
- Documenter les **diligences réalisées**
- Générer un **programme de travail de mission de présentation**
- Constituer un **dossier de travail conforme NEP 2300**
- Sécuriser la **traçabilité et la justification du jugement professionnel**

L’outil ne produit **aucune conclusion autonome**.

---

## 4. Vocabulaire obligatoire

Les termes suivants doivent être utilisés systématiquement :
- mission de présentation des comptes
- diligences
- contrôles de cohérence et de vraisemblance
- jugement professionnel de l’expert-comptable
- éléments probants
- dossier de travail
- assurance modérée

Les termes suivants sont interdits :
- audit
- opinion
- assurance raisonnable
- plan d’audit
- risque d’audit

---

## 5. Contraintes techniques absolues

La solution doit être développée **exclusivement avec l’écosystème Microsoft** :

- Microsoft 365
  - Excel (Power Query, Office Scripts)
  - SharePoint (GED, dossiers de mission)
  - Power Apps (saisie, commentaires, validations)
  - Power Automate (workflows, contrôles, notifications)
- Microsoft Fabric
  - OneLake
  - Dataflows Gen1 / Gen2
  - Fabric SQL Database
- Power BI
  - Modèle sémantique
  - Rapports de contrôle et de synthèse

❌ Aucun outil tiers, aucun framework externe, aucun LLM embarqué.

---

## 6. Gouvernance et responsabilité

- Toute analyse est **proposée**, jamais imposée
- Toute conclusion est **validée par un humain**
- Toute action est **traçable et historisée**

L’outil vise à **sécuriser la responsabilité professionnelle** de l’expert-comptable.

---

## 7. Positionnement mémoire DEC

Ce dépôt s’inscrit dans le cadre du **mémoire DEC** :

> « La Business Intelligence au service de l’expert-comptable pour la mission de présentation – Cas des OPCI »

Chaque composant doit être :
- compréhensible par un expert-comptable
- reproductible sans prestataire externe
- défendable devant un correcteur DEC ou l’OEC


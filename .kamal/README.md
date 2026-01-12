# Configuration Kamal - Workers Solid Queue

Ce dossier contient la configuration pour déployer les workers Solid Queue sur la VM GCP `anaco-workers`.

## Configuration VM GCP

- **Nom**: anaco-workers
- **IP externe**: 34.155.46.127
- **IP interne**: 10.200.0.3
- **Rôle**: Workers Solid Queue pour génération PDF

## Setup initial

### 1. Créer le fichier de secrets

```bash
cp .kamal/secrets-example .kamal/secrets
chmod 600 .kamal/secrets
```

### 2. Éditer `.kamal/secrets` avec vos vraies valeurs

```bash
# Ouvrir avec votre éditeur
nano .kamal/secrets
# ou
code .kamal/secrets
```

Remplissez les valeurs suivantes :
- `KAMAL_REGISTRY_PASSWORD`: Token Docker Hub ou mot de passe
- `SECRET_KEY_BASE`: Générez avec `rails secret`
- `DATABASE_URL`: URL de connexion PostgreSQL (même DB que Cloud Run)
- `RAILS_MASTER_KEY`: Clé dans `config/master.key` ou variable d'env Cloud Run

### 3. Configurer l'accès SSH à la VM GCP

```bash
# Ajouter votre clé SSH publique sur la VM
ssh-copy-id root@34.155.46.127

# Ou manuellement sur GCP Console
# Compute Engine > VM instances > anaco-workers > Edit > SSH Keys
```

### 4. Installer Docker sur la VM (si pas déjà fait)

```bash
ssh root@34.155.46.127

# Installation Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Démarrer Docker
systemctl start docker
systemctl enable docker
```

## Commandes de déploiement

### Premier déploiement (setup)

```bash
# Setup initial (installation de Docker, etc.)
kamal setup

# Ou juste déployer
kamal deploy
```

### Déploiements suivants

```bash
# Déploiement simple
kamal deploy

# Déploiement avec rebuild forcé
kamal deploy --force
```

### Gestion des workers

```bash
# Voir les logs
kamal app logs -f

# Redémarrer les workers
kamal app restart

# Console Rails sur le worker
kamal app exec -i "bin/rails console"

# Shell sur le conteneur
kamal app exec -i "bash"

# SSH direct sur la VM
ssh root@34.155.46.127
```

### Surveillance

```bash
# Status des conteneurs
kamal app details

# Logs en temps réel
kamal app logs --follow

# Vérifier la santé
kamal app containers
```

## Résolution de problèmes

### Les workers ne démarrent pas

```bash
# Vérifier les logs
kamal app logs --tail 100

# Vérifier les variables d'environnement
kamal app exec "env | grep RAILS"

# Redémarrer
kamal app restart
```

### Problème de connexion SSH

```bash
# Tester la connexion
ssh -v root@34.155.46.127

# Vérifier les clés SSH
ls -la ~/.ssh/

# Sur GCP, vérifier les règles firewall
# Compute Engine > VPC network > Firewall > Autoriser SSH (port 22)
```

### Build échoue

```bash
# Build en local puis push
kamal build push

# Ou changer pour build local dans deploy.yml:
# builder:
#   local: true
```

## Architecture

```
┌─────────────────────┐
│   Cloud Run         │
│   (App Rails)       │
│   Port 8080         │
└──────────┬──────────┘
           │
           │ Enqueue jobs
           ▼
┌─────────────────────┐
│   PostgreSQL        │
│   (solid_queue)     │
└──────────┬──────────┘
           │
           │ Polling
           ▼
┌─────────────────────┐
│   VM GCP            │
│   anaco-workers     │
│   34.155.46.127     │
│                     │
│   Docker:           │
│   - Workers         │
│   - Chromium        │
│   - Puppeteer       │
└─────────────────────┘
```

## Sécurité

- ✅ `.kamal/secrets` est dans `.gitignore`
- ✅ Utilisez des variables d'environnement pour les secrets
- ✅ Restreignez l'accès SSH (firewall GCP)
- ✅ Utilisez des clés SSH au lieu de mots de passe
- ✅ Configurez fail2ban sur la VM si nécessaire

## Monitoring

Pour surveiller l'utilisation des ressources sur la VM :

```bash
ssh root@34.155.46.127

# CPU et mémoire
htop

# Docker stats
docker stats

# Logs système
journalctl -u docker -f
```

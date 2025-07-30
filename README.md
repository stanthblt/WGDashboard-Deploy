# 🚀 Déploiement rapide VPN WireGuard + WGDashboard sur Rocky Linux

Bienvenue dans ce dépôt qui permet de déployer **en un clin d’œil** un serveur VPN WireGuard accompagné de son interface web de gestion ultra simple : **WGDashboard** !

Que tu sois admin sys expérimenté ou débutant curieux, ce script va te simplifier la vie pour installer un VPN sécurisé et efficace sur ton serveur, VPS Rocky Linux. Let’s go ! 🎉

## 🔧 Avant de commencer

Avant de lancer la machine, vérifie bien ces petites choses pour éviter les pépins :

-   Ton serveur tourne sous **Rocky Linux 8 ou 9** (on joue la carte de la stabilité)
    
-   Tu as un compte avec droits **sudo** (c’est important !)
    
-   Ton serveur a accès à internet pour télécharger WireGuard, Python & co

## ⚡ Déploiement express

1.  Crée un utilisateur, par exemple `vpn` :
```bash
sudo useradd -m vpn
```

2.  Ensuite, mets-lui un mot de passe :
```bash
sudo passwd vpn
```

3.  Une fois que c’est fait, ajoute-le au groupe `wheel` :
```bash
sudo usermod -aG wheel vpn
```

4.  Clone ce dépôt ou transfère ton script d’installation sur le serveur :
```bash
git clone https://github.com/stanthblt/WGDashboard-Deploy.git && cd WGDashboard-Deploy
```

5.  Rends ton script exécutable :
```bash
chmod +x script.sh
```

6.  Lance la magie avec :

```bash
sudo ./script.sh
```

Le script s’occupe de :

-   Installer WireGuard, Python 3.11 et toutes les dépendances nécessaires
    
-   Installer WGDashboard et créer ses dossiers essentiels (`log/`, `db/`, `download/`)
    
-   Configurer SELinux pour que tout tourne sans accrocs
    
-   Configurer Firewalld pour que les ports soient bien ouverts
    
-   Générer un fichier de configuration WireGuard `/etc/wireguard/wg0.conf`
    
-   Mettre en place un service `vpn`

## 🎉 Après l’installation

1.  Tu peux te rendre sur l’interface web de WGDashboard à l’adresse :
```
http://ipduserveur:10086
```

**Identifiants par défaut :**  
Username : `admin`  
Password : `admin`

Pense à changer username et password, puis crée ton client VPN.

2.  Pour utiliser le VPN, tu peux télécharger le logiciel WireGuard adapté à ton OS ici :  
    [https://www.wireguard.com/install/](https://www.wireguard.com/install/)


## ⚠️ Quelques astuces à garder en tête

-   Toute modification manuelle dans `/etc/wireguard/wg0.conf` nécessite un redémarrage du service WireGuard
    
-   Change le port UDP si tu veux, mais pense à adapter le firewall et les configurations (ex : SELinux)
    
-   Sur Linux, pour les clients, pense à installer `systemd-resolved` et à l’activer avec :
```bash
sudo dnf install systemd-resolved -y && sudo systemctl enable --now systemd-resolved
```

## 🐞 En cas de pépin

-   Logs WGDashboard :
```bash
WGDashboard/src/log/
```
-   Logs du service VPN :
```bash
sudo journalctl -xeu vpn.service
```
-   Statut et statistiques WireGuard :
```bash
sudo wg show
```

## 📚 Ressources utiles

-   WGDashboard : [https://github.com/donaldzou/WGDashboard](https://github.com/donaldzou/WGDashboard)
    
-   WireGuard : [https://www.wireguard.com/](https://www.wireguard.com/)
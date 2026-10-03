# dotfiles

Mes dotfiles pour **macOS**, **Linux desktop** (Ubuntu) et **serveurs Linux**, sur une seule branche.

Inspiré par [jdecool/dotfiles](https://github.com/jdecool/dotfiles) et [jessfraz/dotfiles](https://github.com/jessfraz/dotfiles).

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/babeuloula/dotfiles/main/install.sh | bash
```

`install.sh` :
1. installe le minimum (`git`, `curl` ; sur macOS : Xcode Command Line Tools, Homebrew et un bash récent) ;
2. clone ce dépôt dans `~/.dotfiles` (ou le met à jour s'il existe déjà) ;
3. lance `~/.dotfiles/dotfiles.sh install`.

### Profils

Le profil est détecté automatiquement puis mémorisé dans `~/.local/state/dotfiles/profile` :

| Profil          | Détection                                                         |
|-----------------|-------------------------------------------------------------------|
| `macos`         | `uname` = Darwin                                                  |
| `linux-desktop` | `systemctl get-default` = `graphical.target`, ou un bureau installé (GNOME, KDE, XFCE…) |
| `linux-server`  | `multi-user.target` sans bureau                                   |

Si la détection échoue (conteneur sans systemd…), la question est posée. Pour forcer un profil : `--profile linux-server`.

Les étapes de chaque profil, dans l'ordre, sont listées dans [`profiles/`](profiles).

### Ce qui est installé

- **Tous les profils** : zsh + oh-my-zsh (thème `babeuloula`, `zsh-autosuggestions`), liens vers les configs (`aliases`, `zshrc`, `gitconfig`, `nanorc`, `vimrc`…), psysh, Claude Code (statusline, pas d'attribution dans les commits).
- **Linux (desktop et serveur)** : paquets APT (git, jq, fzf, bat, htop, httpie, rclone, ansible…), Docker, LazyDocker, Terraform.
- **Linux desktop** en plus : Chrome, Firefox, Signal, Tilix, Variety, Meld…, paquets Snap (VS Code, PhpStorm, DataGrip, Slack, Spotify, Discord…), raccourcis clavier GNOME et souris Logitech (logiops, Solaar).
- **macOS** : formules et casks Homebrew (iTerm2, VS Code, PhpStorm, DataGrip, Chrome, Firefox, Signal, Slack, Spotify, Stats, Alt-Tab…), Node.js via nvm, OrbStack + LazyDocker, Logi Options+.

## Mise à jour

Sur un poste déjà installé :

```bash
dotfiles-update        # alias de ~/.dotfiles/dotfiles.sh update
```

La commande fait un `git pull`, puis n'exécute **que les étapes qui ont changé** :
- chaque étape est une fonction shell (`steps/*.sh`) ; son empreinte (sha) est son code plus le contenu des fichiers de `config/` qu'elle copie ou charge ;
- après chaque étape réussie, l'empreinte est enregistrée dans `~/.local/state/dotfiles/steps/` ;
- ajouter un paquet à une liste modifie l'étape : elle est relancée et installe ce qui manque (rien n'est jamais désinstallé) ;
- les fichiers simplement liés (`zshrc`, `aliases`…) sont à jour dès le `git pull` ;
- les étapes préfixées par `always:` dans `profiles/` (ex. la statusline Claude, téléchargée depuis un gist) sont exécutées à chaque fois.

Au premier lancement sur un poste installé avant ce système, aucune étape n'est enregistrée : le script propose de tout exécuter, de tout **marquer comme déjà fait**, ou d'avancer pas à pas.

## Commandes

```
./dotfiles.sh install   installe ce qui n'est pas à jour (reprend là où ça s'est arrêté)
./dotfiles.sh update    git pull puis applique ce qui a changé
./dotfiles.sh status    affiche l'état de chaque étape, sans rien exécuter

Options :
  --step-by-step        demande confirmation avant chaque étape
  --only <étape>        n'exécute que cette étape (répétable)
  --force               exécute toutes les étapes, même à jour
  --profile <profil>    force linux-desktop, linux-server ou macos
```

## En cas d'erreur

Quand une étape échoue, ses dernières lignes de log sont affichées et le script propose **[r]éessayer / [p]asser / [a]rrêter**. Une étape passée ou en échec n'est pas enregistrée : relancer `./dotfiles.sh install` reprend directement sur elle.

- Log complet : `~/.local/state/dotfiles/install.log`
- Relancer une seule étape : `./dotfiles.sh install --only setup_zsh`

## Personnalisation locale

Pour adapter une machine sans toucher au dépôt, créez un fichier `.local` à côté de la config concernée. Ces fichiers ne sont pas versionnés, sont optionnels et sont toujours chargés **après** la config du dépôt : ce qu'ils définissent remplace donc celle-ci.

| Config du dépôt | Surcharge locale | Prise en compte |
|---|---|---|
| `~/.aliases` | `~/.aliases.local` | nouveau shell |
| `~/.functions` | `~/.functions.local` | nouveau shell |
| `~/.dockerfunc` | `~/.dockerfunc.local` | nouveau shell |
| `~/.scaleway` | `~/.scaleway.local` | nouveau shell |
| `~/.zshrc` | `~/.zshrc.local` (chargé en toute fin de `.zshrc`) | nouveau shell |
| `~/.gitconfig` | `~/.gitconfig.local` (via `[include]`, en dernier) | immédiate |
| `~/.vimrc` | `~/.vimrc.local` | prochain `vim` |
| psysh | `~/.psysh/config/config.local.php` | prochain `psysh` |
| Tilix (Linux desktop) | `~/.config/tilix.local.conf` (format `dconf dump`) | `./dotfiles.sh install --only setup_tilix` |

Exemples :

```zsh
# ~/.aliases.local
alias cat="cat"                         # désactive le remplacement par bat
alias proj="cd ~/Sites/mon-projet"

# ~/.zshrc.local
export EDITOR=vim
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=245"
```

```ini
# ~/.gitconfig.local
[user]
    email = moi@entreprise.fr
```

```php
<?php
// ~/.psysh/config/config.local.php : les clés de premier niveau remplacent celles du dépôt
return [
    'updateCheck' => 'never',
];
```

Limites :

- `~/.zshrc.local` est chargé après oh-my-zsh : il ne peut pas changer la liste des `plugins` ni le thème (ils sont déjà chargés). Il peut en revanche définir des variables, des alias, des fonctions, des `setopt`/`unsetopt`, des `bindkey`…
- Git n'accepte qu'un seul `core.excludesfile` : pour ignorer d'autres fichiers sur une machine, pointez-le vers votre propre fichier dans `~/.gitconfig.local` (il remplace alors `~/.gitignore_global`).
- nano, lazydocker et logid n'ont pas de mécanisme d'inclusion : leur config reste celle du dépôt.

## Après l'installation

### macOS

- **Raccourcis clavier** : les raccourcis F13–F18 (Toggle mic, Spotify, iTerm2, PhpStorm, DataGrip, VS Code) se configurent dans `Réglages Système > Clavier > Raccourcis clavier`. Le script de bascule du micro est `~/.local/bin/toggle-mic.sh`.
- **iTerm2** : `Preferences > General > Preferences > Load preferences from a custom folder`.

### Linux desktop

- **Variety** : lancez-le une première fois, puis `./dotfiles.sh install --only setup_variety`.
- Redémarrez la session pour le groupe `docker` et le shell zsh.

## Ajouter une étape

1. Écrire la fonction dans `steps/common.sh`, `steps/linux.sh`, `steps/linux-desktop.sh` ou `steps/macos.sh`, en la rendant relançable (utiliser les helpers de `lib/helpers.sh` : `link_config`, `download`, `apt_install`, `brew_install`, `snap_install`, `add_apt_repo`…).
2. L'ajouter au(x) fichier(s) de `profiles/`.
3. `dotfiles-update` sur les autres postes l'exécutera automatiquement.

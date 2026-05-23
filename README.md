# dotfiles

Inspired by:
- [jdecool/dotfiles](https://github.com/jdecool/dotfiles)
- [jessfraz/dotfiles](https://github.com/jessfraz/dotfiles)

## Installation (macOS)

### Prérequis

- macOS Sequoia (ou plus récent)
- Une connexion internet

### Procédure

```bash
curl -L https://raw.githubusercontent.com/babeuloula/dotfiles/macos/install.sh | bash --
```

Ce script va :
1. Installer les **Xcode Command Line Tools** (si absents)
2. Installer **Homebrew**
3. Cloner ce dépôt dans `~/.dotfiles`
4. Lancer `dotfiles.sh` qui installe et configure tout

### Ce qui est installé

**Outils CLI** : `bat`, `ffmpeg`, `git`, `htop`, `httpie`, `imagemagick`, `jq`, `nano`, `rclone`, `terraform`, `cheat`, `ngrok`, `gnupg`...

**Applications** :
- Navigateurs : Google Chrome, Firefox
- Communication : Signal, Discord, Slack
- Dev : iTerm2, VS Code, PhpStorm, DataGrip, Insomnia
- Médias : Spotify, VLC, GIMP, Steam
- Utilitaires macOS : [Stats](https://github.com/exelban/stats), [Alt-Tab](https://alt-tab-macos.netlify.app), [AppCleaner](https://freemacsoft.net/appcleaner/), [PearCleaner](https://itsalin.com/appInfo/?id=pearcleaner), [Thaw](https://github.com/stonerl/Thaw), [LaunchOS](https://github.com/Remix-Design/LaunchOS), [The Boring Notch](https://github.com/TheBoredTeam/boring.notch)
- Claude : [PromptEdit](https://github.com/mnapoli/PromptEdit), [Claude-God](https://github.com/Lcharvol/Claude-God)
- Cloud : [kDrive (Infomaniak)](https://www.infomaniak.com/fr/apps/kdrive)
- Docker : **OrbStack** + LazyDocker
- Node.js : géré via **nvm** (LTS installée par défaut)
- Souris : **Logi Options+** pour MX Master 3

### Après l'installation

#### Raccourcis clavier

Les raccourcis F13–F18 (Toggle mic, Spotify, iTerm2, PhpStorm, DataGrip, VSCode) doivent être configurés manuellement :

`Réglages Système > Clavier > Raccourcis clavier`

Le script de toggle microphone est disponible dans `~/.local/bin/toggle-mic.sh`.

#### iTerm2

Les préférences iTerm2 se configurent via l'interface graphique :
`Preferences > General > Preferences > Load preferences from a custom folder`

---

## Chrome extensions

- [Adblocks](https://chrome.google.com/webstore/detail/adblock-plus-free-ad-bloc/cfhdojbkjhnklbpkdaibdccddilifddb)
- [EditThisCookie](https://chrome.google.com/webstore/detail/editthiscookie/fngmhnnpilhplaeedifhccceomclgfbg)
- [Refined GitHub](https://chrome.google.com/webstore/detail/refined-github/hlepfoohegkhhmjieoechaddaejaokhf)
- [Sight](https://chrome.google.com/webstore/detail/sight/epmaefhielclhlnmjofcdapbeepkmggh)
- [stylus](https://chrome.google.com/webstore/detail/stylus/clngdbkpkpeebahjckkjfobafhncgmne)
- [Tampermonkey](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo)
- [QookieFix](https://chrome.google.com/webstore/detail/qookiefix/gkfjmfmjckaabogdpclnahenmcijplpe)

## Tampermonkey scripts

- Dark Scripts
	- [Wikipedia](https://github.com/StylishThemes/Wikipedia-Dark)
	- [StackOverflow](https://github.com/StylishThemes/StackOverflow-Dark)
- [Cyprille's scripts](https://github.com/cyprille/tampermonkey-scripts)
	- [Github show hidden conversations](https://raw.githubusercontent.com/cyprille/tampermonkey-scripts/master/scripts/github-show-hidden-conversations.user.js)
- [Github Userscripts](https://github.com/Mottie/GitHub-userscripts)
	- [GitHub Diff Files Filter](https://raw.githubusercontent.com/Mottie/GitHub-userscripts/master/github-diff-files-filter.user.js)
	- [GitHub Indent Comments](https://raw.githubusercontent.com/Mottie/GitHub-userscripts/master/github-indent-comments.user.js)
	- [GitHub Table of Contents](https://raw.githubusercontent.com/Mottie/GitHub-userscripts/master/github-toc.user.js)
	- [GitHub Toggle Diff Comments](https://raw.githubusercontent.com/Mottie/GitHub-userscripts/master/github-toggle-diff-comments.user.js)

## PhpStorm

- [Documentation](https://www.jetbrains.com/help/phpstorm/sharing-your-ide-settings.html#settings-repository)
- [Settings](https://github.com/babeuloula/phpstorm-settings)
- Plugins
	- [.env files support](https://plugins.jetbrains.com/plugin/9525--env-files-support)
	- [CodeGlance3](https://plugins.jetbrains.com/plugin/17017-codeglance3)
	- [Makefile support](https://plugins.jetbrains.com/plugin/9333-makefile-support)
	- [nginx Configuration](https://plugins.jetbrains.com/plugin/15461-nginx-configuration)
	- [PHP Annotations](https://plugins.jetbrains.com/plugin/7320-php-annotations)
	- [PHP composer.json support](https://plugins.jetbrains.com/plugin/7631-php-composer-json-support)
	- [Symfony Support](https://plugins.jetbrains.com/plugin/7219-symfony-support)
	- [.ignore](https://plugins.jetbrains.com/plugin/7495--ignore)
	- [String Manipulation](https://plugins.jetbrains.com/plugin/2162-string-manipulation)
	- [NEON support](https://plugins.jetbrains.com/plugin/7060-neon-support/)
	- [PlantUML integration](https://plugins.jetbrains.com/plugin/7017-plantuml-integration)
	- [Grazie](https://plugins.jetbrains.com/plugin/12175-grazie)

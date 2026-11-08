#!/usr/bin/env bash 
# Script para atuomatizar o pós instalação no Fedora Workstation (Gnome)
# date: 07/11/2026
# Adicionar:
#  	- implementar logs de erro no script
# 	- Melhorar visual usando script com carregamento parecido com braile
# 	- Modularizar podendo escolher o que se deseja instalar
# 	- Ajuste do ambiente Gnome
# 		- [] Considerar formatos United Kingdon


echo '========== Iniciando Pós-Intalação =========='

# configs -----------------------------
set -eE	# e: exit on error, E: trap entra nas funções
mkdir -p $HOME/{GitHub,.log,bin}	# criando diretórios

# trap: executa o CMD quando recebe o sinal passado.
# 	Se usar ' o CMD passado só executa ao recebimento do sinal.
# 	Se usar " o CMD é executado assim a linha do TRAP é lida
trap 'echo "[ERROR] Line $LINENO: $BASH_COMMAND"' ERR 	# msg de erro
trap 'kill 0' EXIT	# mata todos os processos do grupo do processo atual, ou seja, mata os processos em bg criados

# mantendo sudo até finalziar o script
# esse processo é finalizando quando o trap kill 0 é executado
while :; do
	sudo -v  # renova o sudo por mais tempo 
	sleep 60
done & # joga no background

# changing DNF's default answer to Y ([y/N] to [Y/n])
if ! grep -q '^defaultyes' /etc/dnf/dnf.conf; then					 # executa se não tem linha começando em defaultyes
	sudo sed -i.old '/\[main\]/a defaultyes=True' /etc/dnf/dnf.conf  # append a linha após [main] e salva cópia como .old
fi


# Packages ================================================
# atualizando apps e repositórios
sudo dnf -y upgrade
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo  # habilita flatpak (se preciso)

# para o VSCode
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

# para o Starship
sudo dnf -yq copr enable atim/starship
# Após a instalação é necessário colocar em .bashrc:
#eval "$(starship init bash)"
# Como já fiz nos meus dotfiles, pulei essa etapa.


# pacotes para instalação -------------
dnf_install=(
    # RPM Fusion Freen e Nonfree
	https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm        # Free
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm  # Nonfree
	
    # gerais
    gnome-tweaks code
    htop btop fastfetch vim neovim micro rclone git gh starship # utilitário do terminal
	#glycin-thumbnailer	# fix image thumbnails on nautilus
    fira-code-fonts		# fontes
    #libxcrypt-compat	# necessário para referências no LaTeX com biblatex
	ShellCheck

	# nvidia drivers
	akmod-nvidia  # compila o driver quando precisa
	xorg-x11-drv-nvidia-cuda  # (opcional) fornece a interface do CUDA e comando nvidia-smi

    # R e pacotes 
    #R
    #libcurl-devel openssl-devel libxml2-devel fontconfig-devel harfbuzz-devel fribidi-devel
    #freetype-devel libpng-devel libtiff-devel libjpeg-devel libwebp-devel v8-devel
    #gdal-devel proj-devel geos-devel sqlite-devel udunits2 udunits2-devel abseil-cpp-devel
)

flat_install=(
	com.discordapp.Discord
    com.valvesoftware.Steam
    md.obsidian.Obsidian
    com.mattjakeman.ExtensionManager
)

echo 'Instalando aplicativos (dnf)...'
sudo dnf install -yq ${dnf_install[@]}
# alterando editor padrão de nano para vim, para isso é necessária a tag --allowerasing já que ele vai conflitar com o nano
#sudo dnf install -yq --allowerasing vim-default-editor

echo 'Instalando aplicativos (flatpak)...'
flatpak install -y flathub ${flat_install[@]}


# instalações manuais -----------------
# Rstudio (Fedora 41)
#echo 'Instalando Rstudio...'
#wget -O rstudio.rpm https://download1.rstudio.org/electron/rhel9/x86_64/rstudio-2025.09.1-401-x86_64.rpm
#sudo dnf install -y ./rstudio.rpm


# GNOME Configuration =====================================
# configs de ambiente -----------------
echo 'Aplicando configurações no GNOME...'

gsettings set org.gnome.desktop.interface clock-format '24h'
gsettings set org.gnome.desktop.interface cursor-blink false			# disable cursos blink
gsettings set org.gnome.desktop.interface enable-hot-corners false		# disable hot cornor
gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat'	# disable mouse acceleration
gsettings set org.gnome.desktop.session idle-delay 600  				# tempo para desligamento de tela por inatividade
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'       # desativa suspender no carregador
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'  # desativa suspender na bateria
gsettings set org.gnome.Ptyxis cursor-shape 'ibeam'						# cursos I-beam no terminal
gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true	# permite colar com o scroll no terminal (vem desativado desde o GNOME 50)

# resolve problema do alt + shitf + tab e troca de idioma no teclado
gsettings set org.gnome.desktop.input-sources xkb-options "[]"


# Shortcuts -----------------------------
# Verificar quais atalhos já foram definidos:
#	gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings

# Abrir Terminal: <super> + t
slot0='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$slot0 name 'Launch Terminal (Ptyxis)'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$slot0 command 'ptyxis'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$slot0 binding '<Super>t'

# Abrir Nautilus: <super> + f
slot1='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$slot1 name 'Launch File Manager (Nautilus)'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$slot1 command 'nautilus'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$slot1 binding '<Super>f'

# registra atalhos anteriores
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$slot0', '$slot1']"


# dotfiles e gh ===========================================
echo 'Baixando e aplicando dotfiles...'
git clone --bare https://github.com/jsicas/dotfiles.git $HOME/.dotfiles
git --git-dir=$HOME/.dotfiles --work-tree=$HOME checkout -f  # aplica os dotfiles (-f sobrescreve arquivos)
. $HOME/.bashrc  # load alias


#gh auth login -w -c -p https  # gh login -w para web, -c para copiar o código para o clipboard, -p para definir o protocolo


# TeX Live ================================================
echo 'Removendo TeX Live padrão...'
sudo dnf remove -y 'texlive*' nano gnome-clocks
#echo 'Instalando TeX Live...'
#cd $(mktemp -d)  	# vai para um diretório temporário
#texlive_profile=$(mktemp)	# arq temporário para armazenar o perfil
#curl -fsSL 'https://raw.githubusercontent.com/jsicas/pos-install/main/texlive.profile' -o "$texlive_profile"  # salva conteúdo dentro do arq temporário $profile
#wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz  # download zip do texlive
#zcat < install-tl-unx.tar.gz | tar xf -
#cd install-tl-2*
#perl ./install-tl -profile "$texlive_profile"
# Após a instalação é necessário colocar o TeX Live no PATH, no geral isso envolve colocar as seguintes linhas em .bash_profile:
# export PATH="$HOME/.texlive/2025/bin/x86_64-linux:$PATH"
# export MANPATH="$HOME/.texlive/2025/texmf-dist/doc/man:$MANPATH"
# export INFOPATH="$HOME/.texlive/2025/texmf-dist/doc/info:$INFOPATH"

#source $HOME/.bash_profile  # aplicando configurações do PATH para tlmgr funcionar

# instalando pacotes do LaTeX
#tlmgr_install=(
#    mathtools multirow float csquotes xypic algorithm2e ifoddpage relsize
#    caption appendix forest
#)
#tlmgr install ${tlmgr_install[@]}

echo 'Fim da pós instalação.'

# Para finalizar a instalação:
#### Extensões
# - Dash to panel: configurações da barra de tarefas;
# - Dash to dock: dock fica aparecendo
# - Color Picker: lupa para captura de cor;
# - Search light, rofi ou Vicinae: laucher de apps;
# - AppIndicator and KStatusNotifierItem Support: habilita suporte à indicadores na barra de tarefas;
# - Disable unredirect fullscreen windows: resolve problema de tearing em janelas que utilizam aceleração de hardware;
# - Steal my focus window: ao invés de aparecer uma notificação, simplesmente já abre a janela, sem precisar ter que selecionar o popup. 
#### Cron
#0 */2 * * * rclone bisync $HOME/Desktop/mestrado drive:Estudos/mestrado --fast-list --force --recover -v > $HOME/.log/rclone_mestrado.log 2>&1 || notify-send -i dialog-    warning "Erro" "Sincronização dos arquivos com o drive não ocorreu."

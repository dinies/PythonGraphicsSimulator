ARG base_img
FROM $base_img

ARG base_img
ARG ssh_prv_key
ARG ssh_pub_key
ARG git_name
ARG git_email

ENV USERNAME user

ENV DISPLAY :0

RUN apt update && \
  apt install -y \
  sudo \
  git \
  openssh-server \
  vim \
  terminator \
  make \
  locate \
  gnupg2 \
  software-properties-common \
  gdb \
  silversearcher-ag \
  tree \
  tmux

RUN if [ "$base_img" = "ubuntu:bionic" ]; then \
      apt install -y \
      libglu1-mesa-dev \
      freeglut3-dev \
      mesa-common-dev \
      mesa-utils ;\
    fi



# sudoers 
RUN useradd -ms /bin/bash ${USERNAME} && \
  echo "$USERNAME:$USERNAME" | chpasswd && \
  usermod -aG sudo $USERNAME && \
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
  chmod 440 /etc/sudoers.d/$USERNAME


# SSH keys transfer
ARG ssh_dir_path=/home/$USERNAME/.ssh

USER $USERNAME

RUN mkdir -p $ssh_dir_path
RUN ssh-keyscan github.com >> $ssh_dir_path/known_hosts && \
    ssh-keyscan gitlab.inria.fr >> $ssh_dir_path/known_hosts && \
    echo "$ssh_prv_key" > $ssh_dir_path/id_ed25519 && \
    echo "$ssh_pub_key" > $ssh_dir_path/id_ed25519.pub  && \
    sudo chmod 600 $ssh_dir_path/id_ed25519 && \
    sudo chmod 600 $ssh_dir_path/id_ed25519.pub

#cloning repositories
WORKDIR /home/$USERNAME
RUN git clone git@github.com:dinies/dotfiles.git

# Cmake latest version 
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | \
  gpg --dearmor - | \
  sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null && \
  sudo apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main' && \
  sudo apt update && \
  sudo apt install -y \
  cmake \
  cmake-curses-gui

RUN git config --global user.name "$git_name" && \
  git config --global user.email "$git_email" && \
  git config --global push.default simple 

# Upgrade gcc compiler to gcc-10 (not yet tested in the dockerbuilding process)
RUN sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
  sudo apt update && \
  sudo apt install -y gcc-10 g++-10 && \
  sudo update-alternatives \
    --install /usr/bin/gcc gcc /usr/bin/gcc-10 20 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-10

WORKDIR /home/$USERNAME
ENTRYPOINT ["/bin/bash"]

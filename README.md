# AirVPN Hummingbird Client for Docker

#### AirVPN's free and open source OpenVPN 3 client based on AirVPN's OpenVPN 3 library fork - now running in a Docker container

### Based on Version 1.1.2 - Release date 4 June 2021

## Prolog

To make AirVPN's client hummingbird run in a Docker image - and especially
in an Alpine-Linux image - required a few patches to the client as it is
published by AirVPN on gitlab.

I tried to get my patches into their repository at gitlab but there was zero reaction. Thus
I created this github repo, modified my Dockerfiles accordingly and now have an independent
Dockerfile downloading the required sources from their current repository at
https://gitlab.com/AirVPN/hummingbird/-/archive/master/hummingbird-master.tar.bz2

Please open an Issue against this repository, if any problems arise building the image, since
there are no releases in the gitlab repository and this Dockerfile is downloading whatever is
currently in the master branch. Thus the patches may not work anymore if the client code
changes in afore mentioned master branch.

The following is the relevant part of the hummingbird gitlab repository README.md
plus whatever is needed to get this Docker image built and the container running.

**Main features:**

* Lightweight and stand alone binary
* No heavy framework required, no GUI
* Tiny RAM footprint
* Lightning fast
* Based on [OpenVPN 3 library fork by AirVPN](https://github.com/AirVPN/openvpn3-airvpn)
  with tons of critical bug fixes from the main branch, new ciphers support and
  never seen before features
* ChaCha20-Poly1305 cipher support on both Control and Data Channel providing
  great performance boost on ARM, Raspberry PI and any Linux-based platform not
  supporting AES-NI. *Note:* ChaCha20 support for Android had been already
  implemented in [our free and open source Eddie Android edition](https://airvpn.org/forums/topic/44201-eddie-android-edition-24-released-chacha20-support/)
* robust leaks prevention through Network Lock based either on iptables, nftables
  or pf through automatic detection
* proper handling of DNS push by VPN servers, working with resolv.conf as well as
  any operational mode of systemd-resolved additional features
* now also runnable in a Docker container

## Contents

* [Building and Running Hummingbird as Docker Container](#building-and-running-hummingbird-as-docker-container)
  * [Build the Docker Image](#build-the-docker-image)
  * [Run the Hummingbird Docker Image](#run-the-hummingbird-docker-image)
* [Running the Hummingbird Client](#running-the-hummingbird-client)
  * [Start a connection](#start-a-connection)
  * [Stop a connection](#stop-a-connection)
  * [Start a connection with a specific cipher](#start-a-connection-with-a-specific-cipher)
  * [Disable the network filter and lock](#disable-the-network-filter-and-lock)
  * [Ignore the DNS servers pushed by the VPN server](#ignore-the-dns-servers-pushed-by-the-vpn-server)
  * [Controlling Hummingbird](#controlling-hummingbird)
* [Network Filter and Lock](#network-filter-and-lock)
* [DNS Management in Linux](#dns-management-in-linux)
* [DNS Management in macOS](#dns-management-in-macos)
* [Recover Your Network Settings](#recover-your-network-settings)

-------------------------------------------------------------------------------

## Building and Running Hummingbird as Docker Container

# Build the Docker Image

Execute the Docker build command:

>`docker build -t airvpn-hummingbird -f Dockerfile.debian .`
or
>`docker build -t airvpn-hummingbird -f Dockerfile.alpine .`

from the root-directory of this repository. It will result in a new image
**`airvpn-hummingbird`** in your Docker environment.

# Run the airvpn-ummingbird Docker Image

To start the container based on the airvpn-hummingbird image use the following command:

>`docker run -ti --cap-add=NET_ADMIN --cap-add=SYS_MODULE -v /lib/modules:/lib/modules:ro --device /dev/net:/dev/net -v <config.ovpn>:/config.ovpn:ro airvpn-hummingbird <hummingbird-command-options>`

where `<config.ovpn>` is the absolute path to a valid AirVPN configuration file as can be downloaded from the
website's config generator and `<hummingbird-command-options>` should be replaced with any necessary command
options for the hummingbird client - as explained below - to do, what you want it to do.

But be aware, that any `<config-file>` you specify in `<hummingbird-command-options>` must point to a file
**inside the container** and should either be the `/config.ovpn` from the above -v option to the docker run
command or an absolute path to a file you added to the docker image yourself during the build or via docker copy.
If nothing is specified for `<config-file>` in `<hummingbird-command-options>` it will default to `/config.ovpn`.

The part **--cap-add=SYS_MODULE -v /lib/modules:/lib/modules:ro** of the command is necessary to allow the container to actually
load the firewall modules you choose via the `--network-lock` option. If you make sure, the modules are loaded on the Docker host
before you start the container, those are won't be necessary. Therefore it is best, if you choose the network lock type you are
already using on the host anyway and can thus avoid giving the container unnecessary capabilities. Using `--network-lock on` will
require those parameters to be specified, since the hummingbird client will then probe for the modules to figure out for
itself, which firewall modules to use.

Adding `--verbose` to the docker run command's `<hummingbird-command-options>` will produce listings to stderr of all
commands with their input and output that get executed by the hummingbird client in the docker image. A good way to figure
out, what exactly is being done for setting up the network lock.
  
  
# Running the Hummingbird Client

Run `hummingbird` and display its help in order to become familiar with its
options. From your terminal window issue this command:

>`sudo ./hummingbird --help`

After having entered your root account password, `hummingbird` responds with:

>`Hummingbird - AirVPN OpenVPN 3 Client 1.1.2 - 9 April 2021`  
>  
>`usage: hummingbird [options] <config-file>`  
>`--help, -h            : show this help page`  
>`--version, -v         : show version info`  
>`--verbose, -V         : print all executed commands, even if successful`  
>`--eval, -e            : evaluate profile only (standalone)`  
>`--username, -u        : username`  
>`--password, -p        : password`  
>`--response, -r        : static response`  
>`--dc, -D              : dynamic challenge/response cookie`  
>`--cipher, -C          : encrypt packets with specific cipher algorithm (alg)`  
>`--proto, -P           : protocol override (udp|tcp)`  
>`--server, -s          : server override`  
>`--port, -R            : port override`  
>`--tcp-queue-limit, -l : size of TCP packet queue (1-65535, default 8192)`  
>`--ncp-disable, -n     : disable negotiable crypto parameters`  
>`--network-lock, -N    : network filter and lock mode (on|iptables|nftables|pf|off, default on)`  
>`--gui-version, -E     : set custom gui version (text)`  
>`--ignore-dns-push, -i : ignore DNS push request and use system DNS settings`  
>`--combined, -o        : combined IPv4/IPv6 tunnel (yes|no|default)`  
>`--timeout, -t         : timeout`  
>`--compress, -c        : compression mode (yes|no|asym)`  
>`--pk-password, -z     : private key password`  
>`--tvm-override, -M    : tls-version-min override (disabled, default, tls_1_x)`  
>`--tcprof-override, -X : tls-cert-profile override (legacy, preferred, etc.)`  
>`--proxy-host, -y      : HTTP proxy hostname/IP`  
>`--proxy-port, -q      : HTTP proxy port`  
>`--proxy-username, -U  : HTTP proxy username`  
>`--proxy-password, -W  : HTTP proxy password`  
>`--proxy-basic, -b     : allow HTTP basic auth`  
>`--alt-proxy, -A       : enable alternative proxy module`  
>`--cache-password, -H  : cache password`  
>`--no-cert, -x         : disable client certificate`  
>`--def-keydir, -k      : default key direction ('bi', '0', or '1')`  
>`--ssl-debug           : SSL debug level`  
>`--auto-sess, -a       : request autologin session`  
>`--auth-retry, -Y      : retry connection on auth failure`  
>`--persist-tun, -j     : keep TUN interface open across reconnects`  
>`--peer-info, -I       : peer info key/value list in the form K1=V1,K2=V2,...`  
>`--gremlin, -G         : gremlin info (send_delay_ms, recv_delay_ms, send_drop_prob, recv_drop_prob)`  
>`--epki-ca             : simulate external PKI cert supporting intermediate/root certs`  
>`--epki-cert           : simulate external PKI cert`  
>`--epki-key            : simulate external PKI private key`  
>`--recover-network     : recover network settings after a crash or unexpected exit`  
>  
>`Open Source Project by AirVPN (https://airvpn.org)`  
>  
>`Linux and macOS design, development and coding by ProMIND`  
>  
>`Special thanks to the AirVPN community for the valuable help,`  
>`support, suggestions and testing.`  


Hummingbird needs a valid OpenVPN profile in order to connect to a server. You
can create an OpenVPN profile by using the config generator available at AirVPN
website in your account's [Client Area](https://airvpn.org/generator/)


#### Start a connection

>`sudo ./hummingbird your_openvpn_file.ovpn`


#### Stop a connection

Type `CTRL+C` in the terminal window where hummingbird is running. The client
will initiate the disconnection process and will restore your original network
settings according to your options.


#### Start a connection with a specific cipher

>`sudo ./hummingbird --ncp-disable --cipher CHACHA20-POLY1305 your_openvpn_file.ovpn`

**Please note**: in order to properly work, the server you are connecting to
must support the cipher specified with the `--cipher` option.


#### Disable the network filter and lock

>`sudo ./hummingbird --network-lock off your_openvpn_file.ovpn`


#### Ignore the DNS servers pushed by the VPN server

>`sudo ./hummingbird --ignore-dns-push your_openvpn_file.ovpn`


**Please note**: the above options can be combined together according to their
use and function.


#### Controlling Hummingbird

Hummingbird uses the following system signals to control specific actions.
You can send a signal to Hummingbird by using the `kill` command from a terminal.

* **SIGTERM**, **SIGINT**, **SIGPIPE**, **SIGHUP** : Disconnect the active VPN
  connection

* **SIGUSR1**: This is actually a toggle signal to be used to both pause and
  resume VPN connection. In case Goldcrest is connected to a VPN server, the
  connection is paused, whereas in case it is paused, VPN connection will be
  resumed. When the VPN connection is paused, tunnel device status is controlled
  according to `--persist-tun` option. Also consider that pausing and resuming a
  connection is allowed only in case TUN persistence is enabled.

* **SIGUSR2**: Reconnect (restart) the current VPN connection. Reconnecting a
  connection is allowed only in case TUN persistence is enabled.


## Network Filter and Lock

Hummingbird's network filter and lock natively uses `iptables`, `iptables-legacy`,
`nftables` and `pf` in order to provide a "best effort leak prevention". Hummingbird
will automatically detect and use the infrastructure available on your system.

You can also override this default behavior by manually selecting your preferred
firewall by using `--network-lock` option, which defaults to `on` and, in this
specific case, hummingbird will automatically detect and use the firewall installed
on your system by using this specific priority: `iptables-legacy`, `iptables`, 
`nftables` and finally `pf`.

In case you want to force the use of a specific firewall, you can do that by
specifying its name in the `--network-lock` option. For example, in case you want
to force hummingbird to use nftables, you can specify `--network-lock nftables`.
Please note the firewall must be properly installed on your system.

Also note in case both `iptables` and `iptables-legacy` are installed on your system,
hummingbird will use `iptables-legacy`.

**Note on nftables**: Nftables rules created and issued by Hummingbird follow the
specification and behavior of nftables version 0.9. In case you detect nftables
errors or it seems to not be working properly, please check nftables installed
on your system and make sure it is compatible with 0.9 specifications.

**Please note**: Linux services `firewalld` and `ufw` may interfere with the
hummingbird's network filter and lock and you are strongly advised to not issue
any firewall related command while the VPN connection is active.


## DNS Management in Linux

Hummingbird currently supports both `resolv.conf` and `systemd-resolved`
service. It is also aware of Network Manager, in case it is running. While the
client is running, you are strongly advised to not issue any resolved related
command (such as `resolvectl`) or change the `resolv.conf` file in order to make
sure the system properly uses DNS pushed by the VPN server. **Please note**: DNS
system settings are not changed in case the client has been started with
`--ignore-dns-push`. In this specific case, the connection will use your
system's DNS.

Furthermore, please note that if your network interfaces are managed by Network
Manager, DNS settings might be changed under peculiar circumstances during a VPN
connection, even when DNS push had been previously accepted.


## DNS Management in macOS

DNS setting and management is done through OpenVPN 3 native support


## Recover Your Network Settings

In case hummingbird crashes or it is killed by the user (i.e. ``kill -9 `pidof hummingbird` ``)
as well as in case of system reboot while the connection is active, the system
may keep and use some or all of the netwrok settings determined by the client,
therefore your network connection might not work as expected, every connection might
be refused and the system might seem to be "network locked". . To restore and recover
your system network, you can use the client with the `--recover-network` option.

>`sudo ./hummingbird --recover-network`

Please note in case of crash or unexpected exit, when you subsequently run
hummingbird it will warn you about the unexpected exit and will require you to
run it again with the `--recover-network` option. It will also refuse to start
any connection until the network has been properly restored and recovered.
  
In the case of running hummingbird in a Docker container, you can just start the container
with the option `--recover-network` to have everything reset. Or you ca. stop and delete
the container and re-create a new one. But in that case, you'll have to stop, delete and re-create
all containers using the hummingbird-container as their network-providing container, since
that connection is established on the base of the container's UUID, which changes if you
delete and re-create the hummingbird-container.
  
***

Hummingbird is an open source project by [AirVPN](https://airvpn.org)

Linux and macOS design, development and coding by ProMIND

Special thanks to the AirVPN community for the valuable help, support,
suggestions and testing.

OpenVPN is Copyright (C) 2012-2020 OpenVPN Inc. All rights reserved.

Hummingbird is released and licensed under the
[GNU General Public License Version 3 (GPLv3)](https://gitlab.com/AirVPN/hummingbird/blob/master/LICENSE.md)

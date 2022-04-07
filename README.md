# AirVPN Hummingbird Client for Docker

#### AirVPN's free and open source OpenVPN 3 client based on AirVPN's OpenVPN 3 library fork - now running in a Docker container

### Version 1.2.0-1 - Release date 5th April 2022 - patched to run in a docker container and based on offical version
###i# Version 1.2.0 - Release date 22 March 2022

## Prolog

To make AirVPN's client hummingbird run in a Docker image - and especially
in an Alpine-Linux image - required a few patches to the client as it is
published by AirVPN on gitlab.

I tried to get my patches into their repository at gitlab but there was zero reaction. Thus
I created forks of the hummingbird repo on gitlab and the openvpn3-airvpn repo on github,
made my modifications in those and use my own repos to build hummingbird in this Dockerfile.

I'll keep my repos up-to-date with the ones from AirVPN as I find the time, when they release
updates and change this repo's version tag once that is done.

Please open an Issue against this repository, if any problems arise building the image or running
the client inside of it. If it turns out, that the problem lies within the original code, I'll
"forward" the issue to those upstream repositories.

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
* and all of this in an easy to handle Docker container

## Contents

* [Building and Running Hummingbird as Docker Container](#building-and-running-hummingbird-as-docker-container)
  * [Build the Docker Image](#build-the-docker-image)
  * [Run the Hummingbird Docker Image](#run-the-hummingbird-docker-image)
* [Hummingbird Client Command Options](#hummingbird-client-command-options)
  * [Start a connection](#start-a-connection)
  * [Stop a connection](#stop-a-connection)
  * [Start a connection with a specific cipher](#start-a-connection-with-a-specific-cipher)
  * [Disable the network filter and lock](#disable-the-network-filter-and-lock)
  * [Ignore the DNS servers pushed by the VPN server](#ignore-the-dns-servers-pushed-by-the-vpn-server)
  * [Controlling Hummingbird](#controlling-hummingbird)
* [Network Filter and Lock](#network-filter-and-lock)
* [DNS Management in the Container](#dns-management-in-the-container)
* [Recover Your Network Settings](#recover-your-network-settings)

-------------------------------------------------------------------------------

## Building and Running Hummingbird as Docker Container

### Build the Docker Image

Execute the Docker build command:

>`docker build -t airvpn-hummingbird -f Dockerfile .`
from the root-directory of this repository. It will result in a new image
**`airvpn-hummingbird`** in your Docker environment.

### Run the airvpn-hummingbird Docker Image

To start the container based on the airvpn-hummingbird image use the following command:

>`docker run -ti --cap-add=NET_ADMIN --sysctl net.ipv6.conf.all.disable_ipv6=0 --cap-add=SYS_MODULE -v /lib/modules:/lib/modules:ro --device /dev/net:/dev/net -v <config.ovpn>:/config.ovpn:ro airvpn-hummingbird <hummingbird-command-options>`

In the above example, `<config.ovpn>` is the absolute path to a valid AirVPN configuration file as can be downloaded from the
website's config generator and `<hummingbird-command-options>` should contain `/config.ovpn` as a reference to the configuration
file inside the container. For other possible options that can be placed here, see below.

Another example would be:

>`docker run -ti --cap-add=NET_ADMIN --sysctl net.ipv6.conf.all.disable_ipv6=0 --cap-add=SYS_MODULE -v /lib/modules:/lib/modules:ro --device /dev/net:/dev/net -v <config-dir>:/config:ro airvpn-hummingbird <hummingbird-command-options>`

Here the `<hummingbird-command-options>` should contain a reference to an existing file in `<config-dir>`. The path to
the config file in `<hummingbird-command-options>` must be specified as an absolute path **INSIDE** the container, i.e. "/config/Sweden/AirVPN_Sweden_UDP-1194.ovpn".

The part `--cap-add=SYS_MODULE -v /lib/modules:/lib/modules:ro` of the command is necessary to allow the container to actually
probe for and load the firewall modules you choose via the `--network-lock` option.
It is best, if you choose the network lock type you are already using on the host anyway and can thus avoid having the container
load the modules on startup. Also note, that you might need to change the image to contain the other firewall executables, since
this Dockerfile only makes sure that the iptables packages are installed.

`--sysctl net.ipv6.conf.all.disable_ipv6=0` is required to allow the hummingbird client to modify IPv6 routes. Otherwise IPv6 tunneling won't work.

Adding `--verbose` to the docker run command's `<hummingbird-command-options>` will produce listings to stderr of all
commands with their input and output that get executed by the hummingbird client in the docker image. A good way to figure
out, what exactly is being done for setting up the network lock, in case there are any problems with connectivity.
  
  
## Hummingbird Client Command Options

If you run the container without any `<hummingbird-command-options>` it will display its help:

>`Hummingbird - AirVPN OpenVPN 3 Client 1.2.0 - 22 March 2022`
>
>`usage: hummingbird [options] <config-file>`. 
>
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
>`--bypass-vpn, -B      : add routes and network filter expressions to bypass vpn for i.e. local servers (not working for IPv6 yet)`  
>`--gui-version, -E     : set custom gui version (text)`  
>`--ignore-dns-push, -i : ignore DNS push request and use system DNS settings`  
>`--allowuaf, -6        : allow unused address families (yes|no|default)`  
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

*Note that --verbose and --bypass-vpn are additions coming with the docker-enabled hummingbird
client and are not part of the official hummingbird client.*

Hummingbird needs a valid OpenVPN profile in order to connect to a server. You
can create an OpenVPN profile by using the config generator available at AirVPN
website in your account's [Client Area](https://airvpn.org/generator/)


#### Start a connection

To simply start a connection using the docker image, you can replace the
<hummingbird-command-options> part in above `docker run` example with just i.e.
`/config/your_openvpn_file.ovpn` thus specifying nothing other than the profile
the hummingbird-client should use for the connection. The defaults will fill in the rest.


#### Stop a connection

Type `CTRL+C` in the terminal window where the airvpn-hummingbird container is running, if you kept
STDIN open by supplying the -i to the docker run command.
Otherwise issue a `docker stop airvpn-hummingbird` to stop the container.

The client will initiate the disconnection process and will restore the containers original network
settings to what they were before the client started.


#### Start a connection with a specific cipher

Replacing `<hummingbird-command-options>` with `--ncp-disable --cipher CHACHA20-POLY1305 /config/your_openvpn_file.ovpn`
will make the client use the profile `/config/your_openvpn_file.ovpn` but change the cipher to CHACHA20-POLY1305 when
connecting to the server.

**Please note**: in order to properly work, the server you are connecting to
must support the cipher specified with the `--cipher` option.


#### Disable the network filter and lock

To disable the client's built-in network-lock replace `<hummingbird-command-options>`
with `--network-lock off /config/your_openvpn_file.ovpn`. The default for the network
lock is `on`.


#### Ignore the DNS servers pushed by the VPN server

Specifying `--ignore-dns-push /config/your_openvpn_file.ovpn` for
`<hummingbird-command-options>` allows to keep the container's DNS
resolution as it is, disabling the VPN server changing the name servers
on connection.


**Please note**: the above options can be combined together according to their
use and function.


#### Controlling Hummingbird

Hummingbird uses the following system signals to control specific actions.
You can send a signal to Hummingbird by using command
`docker exec -t airvpn-hummingbird killall --signal <SIGNAL> /usr/bin/hummingbird`.

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


## DNS Management in the Container

The Hummingbird client in this container uses the file `resolv.conf` directly.
It creates a backup of the file and writes a new one with the DNS names coming
down from the VPN server.

**Please note**: DNS system settings are not changed in case the container has
been started with `--ignore-dns-push`. In this specific case, the connection will
use your system's DNS as it is passed down into the container by docker.


## Recover Your Network Settings

In case hummingbird crashes or it is killed by the user (i.e. ``kill -9 `pidof hummingbird` ``)
as well as in case of system reboot while the connection is active, the system
may keep and use some or all of the netwrok settings determined by the client,
therefore your network connection might not work as expected, every connection might
be refused and the system might seem to be "network locked". To avoid this problem in the
docker container, the entrypoint.sh, that is started when the container starts, is issuing
a `hummingbird --recover-network` before starting the client to establish a connection.

Thus no specific user action is needed when using hummingbird in this docker container.

In case of problems not fixed with this pre-caution, you may have to delete the container and re-create
it with another docker run command.

But in that case, you'll have to stop, delete and re-create
all containers using the airvpn-hummingbird container as their network-providing container, since
that connection is established on the base of the container's UUID, which changes if you
delete and re-create the airvpn-hummingbird container.
  
***

Hummingbird is an open source project by [AirVPN](https://airvpn.org)

Linux and macOS design, development and coding by ProMIND

Special thanks to the AirVPN community for the valuable help, support,
suggestions and testing.

OpenVPN is Copyright (C) 2012-2020 OpenVPN Inc. All rights reserved.

Hummingbird is released and licensed under the
[GNU General Public License Version 3 (GPLv3)](https://gitlab.com/AirVPN/hummingbird/blob/master/LICENSE.md)

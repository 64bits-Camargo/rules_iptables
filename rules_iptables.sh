#!/bin/bash

start(){
  ## iptables [-t tabela] [opção] [chain] [dados] -j [ação]

  ## Limpar regras antigas
  iptables -F
  iptables -P INPUT ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -P FORWARD ACCEPT

  modprobe ip_tables

  ## Cancelar todas conexões
  iptables -P INPUT DROP
  iptables -P OUTPUT DROP
  iptables -P FORWARD DROP

  ## liberar tráfego na interface loopback/localhost
  iptables -t filter -A INPUT -i lo -j ACCEPT
  iptables -t filter -A OUTPUT -o lo -j ACCEPT
  iptables -t filter -A FORWARD -i lo -j ACCEPT

  ## liberar conexões iniciadas por mim (SEM ISSO A INTERNET NÃO FUNCIONA)
  iptables -t filter -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -t filter -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED,NEW -j ACCEPT

  ## bloqueio IP Address (BLOCK IP)
  iptables -t filter -A INPUT -s 1.2.3.4 -j DROP
  iptables -t filter -A OUTPUT -s 1.2.3.4 -j DROP
  iptables -t filter -A FORWARD -s 1.2.3.4 -j DROP

  ## bloqueio Port Requests (BLOCK PORT)
  iptables -t filter -A INPUT -p tcp --dport 1234 -j DROP
  iptables -t filter -A OUTPUT -p tcp --dport 1234 -j DROP
  iptables -t filter -A FORWARD -p tcp --dport 1234 -j DROP

  ## bloqueio MAC Address (BLOCK MAC)
  iptables -A INPUT -m mac --mac-source 00:11:22:33:44:55 -j DROP

  ## bloqueio Port Scan (BLOCK SCAN)
  iptables -N SCANNER
  iptables -t filter -A SCANNER -j DROP
  iptables -t filter -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -i eth1 -j SCANNER
  iptables -t filter -A INPUT -p tcp --tcp-flags ALL NONE -i eth1 -j SCANNER
  iptables -t filter -A INPUT -p tcp --tcp-flags ALL ALL -i eth1 -j SCANNER
  iptables -t filter -A INPUT -p tcp --tcp-flags ALL FIN,SYN -i eth1 -j SCANNER
  iptables -t filter -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -i eth1 -j SCANNER
  iptables -t filter -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -i eth1 -j SCANNER
  iptables -t filter -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -i eth1 -j SCANNER


  ## prevenir ataque DoS Attack
  iptables -t filter -A INPUT -p tcp -m multiport --dport 22,53,80,443 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT

  ## Liberando SSH(22), HTTP(80,8080), HTTPS(443), FTP(21), TELNET(23), TOR(9159) and DNS(53)
  iptables -t filter -A INPUT -p tcp -m multiport --dport 21,23,22,53,80,443,8080,9150 -j ACCEPT

  ## liberando Ping
  iptables -t filter -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
  iptables -t filter -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT

  iptables -t filter -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT
  iptables -t filter -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

  ## proteção básica dp kernel
  echo 1 > /proc/sys/net/ipv4/tcp_syncookies                    #hablitar o uso do SynCookies
  echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all              #desabilitar o "ping" (Mensagens ICMP) para sua máquina
  echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects         #não aceite redirecionar pacotes ICMP
  echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses #ative a proteção contra respostas a mensagens de erro falsas
  echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts       #evita a peste do Smurf Attack e alguns outros de redes locais

  ## rejeitar conexões depois de fachado o torrent
  iptables -t filter -A INPUT -p tcp --dport 6881 -j REJECT
  iptables -t filter -A INPUT -p udp --dport 6881 -j REJECT

  ## descartar pacotes inválidos
  iptables -A INPUT -m state --state INVALID -j DROP

  ## LOG's
  iptables -t filter -A INPUT -p tcp --dport=20 -j LOG --log-level warning --log-prefix "[firewall] [ftp]"
  iptables -t filter -A INPUT -p udp --dport=20 -j LOG --log-level warning --log-prefix "[firewall] [ftp]"
  iptables -t filter -A INPUT -p tcp --dport=21 -j LOG --log-level warning --log-prefix "[firewall] [ftp]"
  iptables -t filter -A INPUT -p udp --dport=21 -j LOG --log-level warning --log-prefix "[firewall] [ftp]"
  iptables -t filter -A INPUT -p tcp --dport=22 -j LOG --log-level warning --log-prefix "[firewall] [ssh]"
  iptables -t filter -A INPUT -p udp --dport=22 -j LOG --log-level warning --log-prefix "[firewall] [ssh]"
  iptables -t filter -A INPUT -p tcp --dport=23 -j LOG --log-level warning --log-prefix "[firewall] [telnet]"
  iptables -t filter -A INPUT -p udp --dport=23 -j LOG --log-level warning --log-prefix "[firewall] [telnet]"
  iptables -t filter -A SCANNER -m limit --limit 15/m -j LOG --log-level 6 --log-prefix "[firewall] [scan]"
  iptables -t filter -A INPUT -p icmp  -j LOG --log-level warning --log-prefix "[firewall] [ping]"

  echo "firewall-shell start!" > /var/log/firewall-shell.log
}

stop() {
  if [ "$chain" != "Chain INPUT Chain FORWARD Chain OUTPUT" ]; then
		iptables -F
		iptables -P INPUT ACCEPT
		iptables -P OUTPUT ACCEPT
		iptables -P FORWARD ACCEPT
		#adicione as chains personalidas aqui
		iptables -X SCANNER
		else
			iptables -F
			iptables -P INPUT ACCEPT
			iptables -P OUTPUT ACCEPT
			iptables -P FORWARD ACCEPT
	fi

  echo "firewall-shell stop" > /var/log/firewall-shell.log
}

restart() {
  stop
  start
}

case "$1" in
  start) start; echo "start...ok";;
  stop) stop; echo "stop...ok";;
  restart) restart; echo "restart...ok";;
  *) echo -e "\nUsage:\n\t$0 {start|stop|status|restart}"; exit 1;;
esac

exit 0

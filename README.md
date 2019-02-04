<h1>IPTABLES - Regras</h1>

<b>Usar:</b>
~# rules_iptables {start|stop|restart}

<b>Adicionar a inicialização do sistema:</b>
<pre>- Dê permissão de execução no script.
   chmod +x rules_iptables</pre>
<pre>- Mova o script para /etc/init.d/</pre>
<pre>- Use o comando uptade-rc.d
   update-rc.d iptables_rules defaults</pre>

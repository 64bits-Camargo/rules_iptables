<h1>IPTABLES - Regras</h1>

<b>Usar:</b>
<p>~# rules_iptables {start|stop|restart}</p>

<b>Adicionar a inicialização do sistema:</b>
<pre>- Dê permissão de execução no script.
   chmod +x rules_iptables</pre>
<p>- Mova o script para /etc/init.d/</p>
<pre>- Use o comando uptade-rc.d
   update-rc.d iptables_rules defaults</pre>
